package com.readingsanctuary.api.book.extractor;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLDecoder;
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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

@Component
public class EpubMetadataExtractor implements BookMetadataExtractor {

    private static final Logger log = LoggerFactory.getLogger(EpubMetadataExtractor.class);

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
                opfEntry = findZipEntryIgnoreCase(zip, opfPath);
            }

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

            // Estimate pages from spine item count (approx 3 pages per spine document) or null
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
            log.warn("Failed to extract EPUB metadata for {}: {}", originalFileName, e.getMessage());
            throw new IOException("Failed to extract EPUB metadata: " + e.getMessage(), e);
        }
    }

    private String findOpfPath(ZipFile zip) {
        ZipEntry containerEntry = zip.getEntry("META-INF/container.xml");
        if (containerEntry == null) {
            containerEntry = findZipEntryIgnoreCase(zip, "META-INF/container.xml");
        }
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
                String mediaType = item.getAttribute("media-type");
                if (properties != null && properties.contains("cover-image") && isSupportedRasterImage(mediaType, item.getAttribute("href"))) {
                    coverHref = item.getAttribute("href");
                    coverMediaType = mediaType;
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
                            String mediaType = item.getAttribute("media-type");
                            if (isSupportedRasterImage(mediaType, item.getAttribute("href"))) {
                                coverHref = item.getAttribute("href");
                                coverMediaType = mediaType;
                                break;
                            }
                        }
                    }
                }
            }

            // Fallback 1: search items for id or href containing 'cover' and raster image media-type
            if (coverHref == null) {
                for (int i = 0; i < items.getLength(); i++) {
                    Element item = (Element) items.item(i);
                    String href = item.getAttribute("href");
                    String id = item.getAttribute("id");
                    String mediaType = item.getAttribute("media-type");
                    if (isSupportedRasterImage(mediaType, href) &&
                            (href.toLowerCase(Locale.ROOT).contains("cover") || id.toLowerCase(Locale.ROOT).contains("cover"))) {
                        coverHref = href;
                        coverMediaType = mediaType;
                        break;
                    }
                }
            }

            // Fallback 2: check if an XHTML cover page references an image
            if (coverHref == null) {
                for (int i = 0; i < items.getLength(); i++) {
                    Element item = (Element) items.item(i);
                    String href = item.getAttribute("href");
                    String id = item.getAttribute("id");
                    String mediaType = item.getAttribute("media-type");
                    boolean isCoverPage = (href != null && href.toLowerCase(Locale.ROOT).contains("cover")) ||
                            (id != null && id.toLowerCase(Locale.ROOT).contains("cover"));
                    boolean isHtml = mediaType != null && (mediaType.contains("xhtml") || mediaType.contains("html"));

                    if (isCoverPage && isHtml && href != null) {
                        String htmlPath = resolveRelativePath(opfPath, href);
                        ZipEntry htmlEntry = zip.getEntry(htmlPath);
                        if (htmlEntry == null) htmlEntry = findZipEntryIgnoreCase(zip, htmlPath);
                        if (htmlEntry != null) {
                            try (InputStream in = zip.getInputStream(htmlEntry)) {
                                String content = new String(in.readAllBytes(), StandardCharsets.UTF_8);
                                Pattern imgPattern = Pattern.compile("<(?:img|image)[^>]+(?:src|href|xlink:href)=[\"']([^\"']+)[\"']", Pattern.CASE_INSENSITIVE);
                                Matcher m = imgPattern.matcher(content);
                                while (m.find()) {
                                    String candidateImg = m.group(1);
                                    if (isSupportedRasterImage(null, candidateImg)) {
                                        coverHref = resolveRelativePath(htmlPath, candidateImg);
                                        // coverHref is now already relative to ZIP root, adjust so resolveRelativePath below handles it
                                        coverMediaType = guessMimeType(candidateImg);
                                        break;
                                    }
                                }
                            } catch (Exception ignored) {}
                        }
                    }
                    if (coverHref != null) break;
                }
            }

            // Fallback 3: search zip entries directly for standalone cover files
            if (coverHref == null) {
                Enumeration<? extends ZipEntry> allEntries = zip.entries();
                while (allEntries.hasMoreElements()) {
                    ZipEntry e = allEntries.nextElement();
                    String name = e.getName();
                    String simpleName = name.substring(name.lastIndexOf('/') + 1).toLowerCase(Locale.ROOT);
                    if (simpleName.startsWith("cover.") && isSupportedRasterImage(null, simpleName)) {
                        coverHref = name;
                        coverMediaType = guessMimeType(simpleName);
                        break;
                    }
                }
            }

            if (coverHref == null) return null;

            // Handle URL-encoded paths (e.g. "cover%20art.jpg")
            try {
                coverHref = URLDecoder.decode(coverHref, StandardCharsets.UTF_8);
            } catch (Exception ignored) {}

            String coverPath = resolveRelativePath(opfPath, coverHref);
            ZipEntry coverEntry = zip.getEntry(coverPath);
            if (coverEntry == null) {
                coverEntry = findZipEntryIgnoreCase(zip, coverPath);
            }

            if (coverEntry != null) {
                try (InputStream in = zip.getInputStream(coverEntry)) {
                    byte[] bytes = in.readAllBytes();
                    if (bytes.length > 0 && bytes.length <= 5 * 1024 * 1024) { // max 5MB
                        String mime = (coverMediaType != null && !coverMediaType.isBlank()) ? coverMediaType : guessMimeType(coverPath);
                        return "data:" + mime + ";base64," + Base64.getEncoder().encodeToString(bytes);
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Error extracting cover image from EPUB: {}", e.getMessage());
        }
        return null;
    }

    private String resolveRelativePath(String basePath, String relativePath) {
        if (relativePath == null) return "";
        if (relativePath.startsWith("/")) {
            relativePath = relativePath.substring(1);
        }
        String combined;
        int lastSlash = basePath != null ? basePath.lastIndexOf('/') : -1;
        if (lastSlash >= 0) {
            combined = basePath.substring(0, lastSlash + 1) + relativePath;
        } else {
            combined = relativePath;
        }
        return normalizePath(combined);
    }

    private String normalizePath(String path) {
        if (path == null) return "";
        String[] parts = path.replace('\\', '/').split("/");
        java.util.List<String> segments = new java.util.ArrayList<>();
        for (String part : parts) {
            if (part.isEmpty() || part.equals(".")) continue;
            if (part.equals("..")) {
                if (!segments.isEmpty()) {
                    segments.remove(segments.size() - 1);
                }
            } else {
                segments.add(part);
            }
        }
        return String.join("/", segments);
    }

    private String guessMimeType(String fileName) {
        if (fileName == null) return "image/jpeg";
        String lower = fileName.toLowerCase(Locale.ROOT);
        if (lower.endsWith(".png")) return "image/png";
        if (lower.endsWith(".webp")) return "image/webp";
        return "image/jpeg";
    }

    private boolean isSupportedRasterImage(String mediaType, String href) {
        if (mediaType != null) {
            String m = mediaType.toLowerCase(Locale.ROOT);
            if (m.contains("svg")) return false; // skip SVG
            if (m.equals("image/jpeg") || m.equals("image/jpg") || m.equals("image/png") || m.equals("image/webp")) {
                return true;
            }
        }
        if (href != null) {
            String h = href.toLowerCase(Locale.ROOT);
            if (h.endsWith(".svg")) return false;
            return h.endsWith(".jpg") || h.endsWith(".jpeg") || h.endsWith(".png") || h.endsWith(".webp");
        }
        return false;
    }

    private ZipEntry findZipEntryIgnoreCase(ZipFile zip, String path) {
        String cleanPath = path.replace('\\', '/');
        Enumeration<? extends ZipEntry> entries = zip.entries();
        while (entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            if (entry.getName().equalsIgnoreCase(cleanPath)) {
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
