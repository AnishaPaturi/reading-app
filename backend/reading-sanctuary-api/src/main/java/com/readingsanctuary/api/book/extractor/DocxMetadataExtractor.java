package com.readingsanctuary.api.book.extractor;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Base64;
import java.util.Enumeration;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipFile;
import java.util.zip.ZipInputStream;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.apache.tika.metadata.Metadata;
import org.apache.tika.metadata.Office;
import org.apache.tika.metadata.TikaCoreProperties;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.sax.BodyContentHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

@Component
public class DocxMetadataExtractor implements BookMetadataExtractor {

    private static final Logger log = LoggerFactory.getLogger(DocxMetadataExtractor.class);
    private static final int MAX_EXTRACT_TEXT_CHARS = 100_000;
    private static final long MAX_COVER_BYTES = 5L * 1024 * 1024; // 5 MB

    @Override
    public boolean supports(String fileExtension) {
        return fileExtension != null && "docx".equalsIgnoreCase(fileExtension.trim());
    }

    /**
     * Validates that the file is a readable ZIP archive containing a valid OOXML
     * WordprocessingML package structure, specifically requiring [Content_Types].xml
     * and word/document.xml.
     *
     * @param file the candidate DOCX file
     * @throws IOException if the file is not a valid zip, missing required parts, or contains invalid OOXML XML
     */
    public void validateDocxPackage(File file) throws IOException {
        if (file == null || !file.exists() || file.length() < 4) {
            throw new IOException("DOCX file is empty or does not exist");
        }

        try (ZipFile zipFile = new ZipFile(file)) {
            // 1. Locate and validate [Content_Types].xml
            ZipEntry contentTypesEntry = findZipEntryIgnoreCase(zipFile, "[Content_Types].xml");
            if (contentTypesEntry == null) {
                throw new IOException("Invalid DOCX package: missing [Content_Types].xml");
            }
            try (InputStream is = zipFile.getInputStream(contentTypesEntry)) {
                validateXmlWellFormed(is, "Types");
            } catch (IOException e) {
                throw e;
            } catch (Exception e) {
                throw new IOException("Invalid OOXML structure in [Content_Types].xml: " + e.getMessage(), e);
            }

            // 2. Locate and validate word/document.xml
            ZipEntry docEntry = findZipEntryIgnoreCase(zipFile, "word/document.xml");
            if (docEntry == null) {
                throw new IOException("Invalid DOCX package: missing word/document.xml");
            }
            try (InputStream docStream = zipFile.getInputStream(docEntry)) {
                validateXmlWellFormed(docStream, "document");
            } catch (IOException e) {
                throw e;
            } catch (Exception e) {
                throw new IOException("Invalid OOXML structure in word/document.xml: " + e.getMessage(), e);
            }
        } catch (ZipException e) {
            throw new IOException("Corrupted or invalid ZIP archive for DOCX: " + e.getMessage(), e);
        }
    }

    private ZipEntry findZipEntryIgnoreCase(ZipFile zipFile, String targetName) {
        ZipEntry direct = zipFile.getEntry(targetName);
        if (direct != null) return direct;
        Enumeration<? extends ZipEntry> entries = zipFile.entries();
        while (entries.hasMoreElements()) {
            ZipEntry e = entries.nextElement();
            if (targetName.equalsIgnoreCase(e.getName())) {
                return e;
            }
        }
        return null;
    }

    private void validateXmlWellFormed(InputStream is, String expectedRootLocalName) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        factory.setFeature("http://javax.xml.XMLConstants/feature/secure-processing", true);
        factory.setNamespaceAware(true);
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document doc = builder.parse(is);

        Element root = doc.getDocumentElement();
        if (root == null) {
            throw new IOException("Empty XML document");
        }

        if (expectedRootLocalName != null) {
            String localName = root.getLocalName() != null ? root.getLocalName() : root.getTagName();
            if (localName.contains(":")) {
                localName = localName.substring(localName.indexOf(':') + 1);
            }
            if (!expectedRootLocalName.equalsIgnoreCase(localName)) {
                throw new IOException("Root element is not " + expectedRootLocalName + ", found: " + root.getTagName());
            }
        }
    }

    @Override
    public ExtractedBookMetadata extract(File file, String originalFileName) throws IOException {
        validateDocxPackage(file);

        String title = null;
        String author = null;
        String description = null;
        String language = "en";
        Integer pages = null;
        String coverBase64 = null;

        AutoDetectParser parser = new AutoDetectParser();
        Metadata metadata = new Metadata();
        BodyContentHandler handler = new BodyContentHandler(MAX_EXTRACT_TEXT_CHARS);
        ParseContext context = new ParseContext();

        try (InputStream is = new FileInputStream(file)) {
            parser.parse(is, handler, metadata, context);

            title = sanitize(metadata.get(TikaCoreProperties.TITLE));
            if (title == null || title.isBlank()) {
                title = sanitize(metadata.get("dc:title"));
            }

            author = sanitize(metadata.get(TikaCoreProperties.CREATOR));
            if (author == null || author.isBlank()) {
                author = sanitize(metadata.get("dc:creator"));
            }
            if (author == null || author.isBlank()) {
                author = sanitize(metadata.get("author"));
            }

            description = sanitize(metadata.get(TikaCoreProperties.DESCRIPTION));
            if (description == null || description.isBlank()) {
                description = sanitize(metadata.get("dc:description"));
            }
            if (description == null || description.isBlank()) {
                description = sanitize(metadata.get("subject"));
            }

            String lang = metadata.get(TikaCoreProperties.LANGUAGE);
            if (lang != null && !lang.isBlank()) {
                language = lang.trim();
            }

            // Page count estimation
            String pageCountStr = metadata.get(Office.PAGE_COUNT);
            if (pageCountStr == null || pageCountStr.isBlank()) {
                pageCountStr = metadata.get("Page-Count");
            }
            if (pageCountStr != null && !pageCountStr.isBlank()) {
                try {
                    int p = Integer.parseInt(pageCountStr.trim());
                    if (p > 0) pages = p;
                } catch (NumberFormatException ignored) {}
            }

            if (pages == null) {
                // Try word count
                String wordCountStr = metadata.get(Office.WORD_COUNT);
                if (wordCountStr == null || wordCountStr.isBlank()) {
                    wordCountStr = metadata.get("Word-Count");
                }
                int words = 0;
                if (wordCountStr != null && !wordCountStr.isBlank()) {
                    try {
                        words = Integer.parseInt(wordCountStr.trim());
                    } catch (NumberFormatException ignored) {}
                }
                if (words <= 0) {
                    String extractedText = handler.toString();
                    if (!extractedText.isBlank()) {
                        words = extractedText.split("\\s+").length;
                    }
                }
                if (words > 0) {
                    pages = Math.max(1, (int) Math.ceil(words / 250.0));
                }
            }

        } catch (Exception e) {
            log.warn("Tika failed to parse metadata for DOCX file {}: {}", originalFileName, e.getMessage());
        }

        // Try to extract cover image and fallback core properties from DOCX zip package
        try {
            DocxPackageData packageData = extractFromDocxZip(file);
            if (coverBase64 == null) {
                coverBase64 = packageData.coverBase64;
            }
            if (title == null || title.isBlank() || isGenericDocxTitle(title)) {
                if (packageData.title != null && !packageData.title.isBlank()) {
                    title = packageData.title;
                }
            }
            if (author == null || author.isBlank()) {
                if (packageData.author != null && !packageData.author.isBlank()) {
                    author = packageData.author;
                }
            }
            if (description == null || description.isBlank()) {
                if (packageData.description != null && !packageData.description.isBlank()) {
                    description = packageData.description;
                }
            }
            if (pages == null && packageData.pages != null && packageData.pages > 0) {
                pages = packageData.pages;
            }
        } catch (Exception e) {
            log.debug("No additional data extracted from DOCX zip {}: {}", originalFileName, e.getMessage());
        }

        if (title == null || title.isBlank() || isGenericDocxTitle(title)) {
            title = formatDefaultTitle(originalFileName);
        }

        return new ExtractedBookMetadata(
                title,
                author,
                "Non-Fiction",
                description,
                null,
                pages,
                null,
                language,
                coverBase64
        );
    }

    private static class DocxPackageData {
        String title;
        String author;
        String description;
        Integer pages;
        String coverBase64;
    }

    private DocxPackageData extractFromDocxZip(File file) {
        DocxPackageData data = new DocxPackageData();
        try (ZipInputStream zis = new ZipInputStream(new FileInputStream(file))) {
            ZipEntry entry;
            byte[] firstMediaImage = null;
            String firstMediaImageExt = null;

            while ((entry = zis.getNextEntry()) != null) {
                String name = entry.getName().toLowerCase(Locale.ROOT);

                // Priority 1: Built-in thumbnail preview
                if (name.equals("docprops/thumbnail.jpeg") || name.equals("docprops/thumbnail.jpg")) {
                    byte[] bytes = zis.readAllBytes();
                    if (bytes.length > 0 && bytes.length <= MAX_COVER_BYTES) {
                        data.coverBase64 = "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(bytes);
                    }
                }

                // Priority 2: Direct core properties parse (dc:title, dc:creator, dc:description)
                if (name.equals("docprops/core.xml")) {
                    String xml = new String(zis.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
                    data.title = extractTagContent(xml, "dc:title");
                    data.author = extractTagContent(xml, "dc:creator");
                    data.description = extractTagContent(xml, "dc:description");
                }

                // Priority 3: Direct app properties parse (Pages, Words)
                if (name.equals("docprops/app.xml")) {
                    String xml = new String(zis.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
                    String pagesStr = extractTagContent(xml, "Pages");
                    if (pagesStr != null && !pagesStr.isBlank()) {
                        try {
                            int p = Integer.parseInt(pagesStr.trim());
                            if (p > 0) data.pages = p;
                        } catch (NumberFormatException ignored) {}
                    }
                    if (data.pages == null) {
                        String wordsStr = extractTagContent(xml, "Words");
                        if (wordsStr != null && !wordsStr.isBlank()) {
                            try {
                                int w = Integer.parseInt(wordsStr.trim());
                                if (w > 0) data.pages = Math.max(1, (int) Math.ceil(w / 250.0));
                            } catch (NumberFormatException ignored) {}
                        }
                    }
                }

                // Priority 4: First embedded media image (word/media/image1.png / image1.jpeg)
                if (firstMediaImage == null && name.startsWith("word/media/image1.")) {
                    if (name.endsWith(".jpg") || name.endsWith(".jpeg")) {
                        firstMediaImage = zis.readAllBytes();
                        firstMediaImageExt = "jpeg";
                    } else if (name.endsWith(".png")) {
                        firstMediaImage = zis.readAllBytes();
                        firstMediaImageExt = "png";
                    }
                }
                zis.closeEntry();
            }

            if (data.coverBase64 == null && firstMediaImage != null && firstMediaImage.length > 0 && firstMediaImage.length <= MAX_COVER_BYTES) {
                data.coverBase64 = "data:image/" + firstMediaImageExt + ";base64," + Base64.getEncoder().encodeToString(firstMediaImage);
            }
        } catch (Exception e) {
            log.debug("Could not inspect DOCX zip for package data: {}", e.getMessage());
        }
        return data;
    }

    private String extractTagContent(String xml, String tag) {
        if (xml == null || tag == null) return null;
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(
                "<" + tag + "[^>]*>(.*?)</" + tag + ">",
                java.util.regex.Pattern.DOTALL | java.util.regex.Pattern.CASE_INSENSITIVE
        );
        java.util.regex.Matcher matcher = pattern.matcher(xml);
        if (matcher.find()) {
            String val = matcher.group(1).trim();
            return val.isEmpty() ? null : val;
        }
        return null;
    }

    private boolean isGenericDocxTitle(String title) {
        String lower = title.toLowerCase(Locale.ROOT);
        return lower.startsWith("microsoft word") ||
               lower.equals("document") ||
               lower.equals("word document") ||
               lower.equals("untitled") ||
               lower.equals("title");
    }

    private String formatDefaultTitle(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) return "Untitled Document";
        String clean = originalFileName.replace("\\", "/");
        clean = clean.substring(clean.lastIndexOf('/') + 1);
        int dot = clean.lastIndexOf('.');
        if (dot > 0) clean = clean.substring(0, dot);
        return clean.replace('_', ' ').replace('-', ' ').trim();
    }

    private String sanitize(String input) {
        if (input == null || input.isBlank()) return null;
        String trimmed = input.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
