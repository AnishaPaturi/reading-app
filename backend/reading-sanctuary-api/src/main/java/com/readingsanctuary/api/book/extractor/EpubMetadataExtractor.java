package com.readingsanctuary.api.book.extractor;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Enumeration;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.springframework.stereotype.Component;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

@Component
public class EpubMetadataExtractor implements BookMetadataExtractor {

    private static final Pattern ROOTFILE_PATTERN = Pattern.compile(
            "<rootfile[^>]*full-path=[\"']([^\"']+)[\"'][^>]*>",
            Pattern.CASE_INSENSITIVE
    );

    @Override
    public boolean supports(String fileExtension) {
        return fileExtension != null && "epub".equalsIgnoreCase(fileExtension.trim());
    }

    @Override
    public ExtractedBookMetadata extract(File file, String originalFileName) throws IOException {
        try (ZipFile zip = new ZipFile(file)) {
            // 1. Locate OPF file path from META-INF/container.xml
            String opfPath = findOpfPath(zip);
            if (opfPath == null) {
                // Fallback: search zip entries for any .opf file
                opfPath = findAnyOpfEntry(zip);
            }

            if (opfPath == null) {
                return new ExtractedBookMetadata(
                        formatDefaultTitle(originalFileName),
                        null, "Fiction", null, null, null, null, "en", null
                );
            }

            ZipEntry opfEntry = zip.getEntry(opfPath);
            if (opfEntry == null) {
                return new ExtractedBookMetadata(
                        formatDefaultTitle(originalFileName),
                        null, "Fiction", null, null, null, null, "en", null
                );
            }

            // 2. Parse OPF XML securely
            Document doc = parseXml(zip.getInputStream(opfEntry));

            String title = getTagValue(doc, "dc:title");
            if (title == null || title.isBlank()) {
                title = getTagValue(doc, "title");
            }
            if (title == null || title.isBlank()) {
                title = formatDefaultTitle(originalFileName);
            }

            String author = getTagValue(doc, "dc:creator");
            if (author == null) author = getTagValue(doc, "creator");

            String language = getTagValue(doc, "dc:language");
            if (language == null) language = "en";

            String identifier = getTagValue(doc, "dc:identifier");
            String isbn = null;
            if (identifier != null && (identifier.contains("isbn") || identifier.replaceAll("[^0-9X]", "").length() >= 10)) {
                isbn = identifier.replaceAll("(?i)urn:isbn:", "").trim();
            }

            String description = getTagValue(doc, "dc:description");
            String subject = getTagValue(doc, "dc:subject");
            String genre = subject != null && !subject.isBlank() ? subject : "Fiction";

            // 3. Extract Cover Image
            String coverBase64 = extractCoverImage(zip, doc, opfPath);

            // Estimate pages from spine item count (approx 2.5 pages per spine document) or null
            Integer pages = null;
            NodeList itemrefs = doc.getElementsByTagName("itemref");
            if (itemrefs != null && itemrefs.getLength() > 0) {
                pages = Math.max(10, itemrefs.getLength() * 3);
            }

            return new ExtractedBookMetadata(
                    title,
                    author,
                    genre,
                    description,
                    isbn,
                    pages,
                    null,
                    language,
                    coverBase64
            );
        } catch (Exception e) {
            throw new IOException("Failed to extract EPUB metadata: " + e.getMessage(), e);
        }
    }

    private String findOpfPath(ZipFile zip) {
        ZipEntry containerEntry = zip.getEntry("META-INF/container.xml");
        if (containerEntry == null) return null;

        try (InputStream in = zip.getInputStream(containerEntry)) {
            String xml = new String(in.readAllBytes(), StandardCharsets.UTF_8);
            Matcher matcher = ROOTFILE_PATTERN.matcher(xml);
            if (matcher.find()) {
                return matcher.group(1).trim();
            }
        } catch (Exception ignored) {}
        return null;
    }

    private String findAnyOpfEntry(ZipFile zip) {
        Enumeration<? extends ZipEntry> entries = zip.entries();
        while (entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            if (entry.getName().toLowerCase(Locale.ROOT).endsWith(".opf")) {
                return entry.getName();
            }
        }
        return null;
    }

    private Document parseXml(InputStream inputStream) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(false);
        factory.setValidating(false);
        // Disable external entities to prevent XXE attacks
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", false);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        DocumentBuilder builder = factory.newDocumentBuilder();
        return builder.parse(inputStream);
    }

    private String getTagValue(Document doc, String tagName) {
        NodeList nodes = doc.getElementsByTagName(tagName);
        if (nodes != null && nodes.getLength() > 0) {
            String content = nodes.item(0).getTextContent();
            if (content != null && !content.isBlank()) {
                return content.trim();
            }
        }
        return null;
    }

    private String extractCoverImage(ZipFile zip, Document opfDoc, String opfPath) {
        try {
            String coverHref = null;
            String coverMediaType = "image/jpeg";

            // Check EPUB 3: <item properties="cover-image" ...>
            NodeList items = opfDoc.getElementsByTagName("item");
            for (int i = 0; i < items.getLength(); i++) {
                Element item = (Element) items.item(i);
                String properties = item.getAttribute("properties");
                if (properties != null && properties.contains("cover-image")) {
                    coverHref = item.getAttribute("href");
                    coverMediaType = item.getAttribute("media-type");
                    break;
                }
            }

            // Check EPUB 2: <meta name="cover" content="item-id">
            if (coverHref == null) {
                NodeList metas = opfDoc.getElementsByTagName("meta");
                String coverItemId = null;
                for (int i = 0; i < metas.getLength(); i++) {
                    Element meta = (Element) metas.item(i);
                    if ("cover".equalsIgnoreCase(meta.getAttribute("name"))) {
                        coverItemId = meta.getAttribute("content");
                        break;
                    }
                }
                if (coverItemId != null) {
                    for (int i = 0; i < items.getLength(); i++) {
                        Element item = (Element) items.item(i);
                        if (coverItemId.equalsIgnoreCase(item.getAttribute("id"))) {
                            coverHref = item.getAttribute("href");
                            coverMediaType = item.getAttribute("media-type");
                            break;
                        }
                    }
                }
            }

            // Fallback: search items for id or href containing 'cover' and image media-type
            if (coverHref == null) {
                for (int i = 0; i < items.getLength(); i++) {
                    Element item = (Element) items.item(i);
                    String href = item.getAttribute("href");
                    String id = item.getAttribute("id");
                    String mediaType = item.getAttribute("media-type");
                    if (mediaType != null && mediaType.startsWith("image/") &&
                            (href.toLowerCase(Locale.ROOT).contains("cover") || id.toLowerCase(Locale.ROOT).contains("cover"))) {
                        coverHref = href;
                        coverMediaType = mediaType;
                        break;
                    }
                }
            }

            if (coverHref == null) return null;

            // Resolve path relative to OPF file
            String coverPath;
            int lastSlash = opfPath.lastIndexOf('/');
            if (lastSlash >= 0) {
                coverPath = opfPath.substring(0, lastSlash + 1) + coverHref;
            } else {
                coverPath = coverHref;
            }

            // Normalize path (handle ../)
            coverPath = java.nio.file.Path.of(coverPath).normalize().toString().replace('\\', '/');
            ZipEntry coverEntry = zip.getEntry(coverPath);
            if (coverEntry == null) {
                // Try case-insensitive search
                coverEntry = findZipEntryIgnoreCase(zip, coverPath);
            }

            if (coverEntry != null) {
                try (InputStream in = zip.getInputStream(coverEntry)) {
                    byte[] bytes = in.readAllBytes();
                    if (bytes.length > 0 && bytes.length <= 10 * 1024 * 1024) { // max 10MB
                        String mime = coverMediaType != null && !coverMediaType.isBlank() ? coverMediaType : "image/jpeg";
                        return "data:" + mime + ";base64," + Base64.getEncoder().encodeToString(bytes);
                    }
                }
            }
        } catch (Exception ignored) {}
        return null;
    }

    private ZipEntry findZipEntryIgnoreCase(ZipFile zip, String path) {
        Enumeration<? extends ZipEntry> entries = zip.entries();
        while (entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            if (entry.getName().equalsIgnoreCase(path)) {
                return entry;
            }
        }
        return null;
    }

    private String formatDefaultTitle(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) return "Untitled Book";
        String clean = originalFileName.replace("\\", "/");
        clean = clean.substring(clean.lastIndexOf('/') + 1);
        int dot = clean.lastIndexOf('.');
        if (dot > 0) clean = clean.substring(0, dot);
        return clean.replace('_', ' ').replace('-', ' ').trim();
    }
}
