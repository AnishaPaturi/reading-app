package com.readingsanctuary.api.book.extractor;

import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.util.Base64;
import javax.imageio.ImageIO;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class PdfMetadataExtractor implements BookMetadataExtractor {

    private static final Logger log = LoggerFactory.getLogger(PdfMetadataExtractor.class);
    private static final float RENDER_DPI = 120.0f;
    private static final int MAX_COVER_WIDTH = 1200;
    private static final int MAX_COVER_HEIGHT = 1600;

    @Override
    public boolean supports(String fileExtension) {
        return fileExtension != null && "pdf".equalsIgnoreCase(fileExtension.trim());
    }

    @Override
    public ExtractedBookMetadata extract(File file, String originalFileName) throws IOException {
        String title = null;
        String author = null;
        String description = null;
        int pages = 0;
        String coverBase64 = null;

        try (PDDocument document = Loader.loadPDF(file)) {
            pages = document.getNumberOfPages();
            PDDocumentInformation info = document.getDocumentInformation();

            if (info != null) {
                title = sanitize(info.getTitle());
                author = sanitize(info.getAuthor());
                description = sanitize(info.getSubject());
            }

            // Extract cover from the first page (index 0) if available and not encrypted
            if (pages > 0 && !document.isEncrypted()) {
                coverBase64 = renderFirstPageAsCover(document, originalFileName);
            }
        } catch (Exception e) {
            log.warn("Failed to parse PDF metadata or render cover for {}: {}", originalFileName, e.getMessage());
            throw new IOException("Failed to parse PDF metadata: " + e.getMessage(), e);
        }

        if (title == null || title.isBlank()) {
            title = formatDefaultTitle(originalFileName);
        }

        return new ExtractedBookMetadata(
                title,
                author,
                "Non-Fiction",
                description,
                null,
                pages > 0 ? pages : null,
                null,
                "en",
                coverBase64
        );
    }

    private String renderFirstPageAsCover(PDDocument document, String originalFileName) {
        try {
            PDFRenderer renderer = new PDFRenderer(document);
            // Render first page at 120 DPI in RGB
            BufferedImage image = renderer.renderImageWithDPI(0, RENDER_DPI, ImageType.RGB);
            if (image == null) {
                return null;
            }

            // Downscale if image dimensions exceed maximum bounds to limit memory & file size
            if (image.getWidth() > MAX_COVER_WIDTH || image.getHeight() > MAX_COVER_HEIGHT) {
                image = scaleImage(image, MAX_COVER_WIDTH, MAX_COVER_HEIGHT);
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            boolean written = ImageIO.write(image, "jpeg", baos);
            if (!written) {
                written = ImageIO.write(image, "jpg", baos);
            }

            if (written && baos.size() > 0) {
                byte[] bytes = baos.toByteArray();
                if (bytes.length <= 10 * 1024 * 1024) { // max 10MB
                    return "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(bytes);
                }
            }
        } catch (Throwable t) {
            log.warn("Could not render first page of PDF as cover for {}: {}", originalFileName, t.getMessage());
        }
        return null;
    }

    private BufferedImage scaleImage(BufferedImage original, int maxWidth, int maxHeight) {
        int width = original.getWidth();
        int height = original.getHeight();

        double widthRatio = (double) maxWidth / width;
        double heightRatio = (double) maxHeight / height;
        double ratio = Math.min(widthRatio, heightRatio);

        int targetWidth = (int) Math.round(width * ratio);
        int targetHeight = (int) Math.round(height * ratio);

        BufferedImage scaled = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = scaled.createGraphics();
        try {
            g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2d.drawImage(original, 0, 0, targetWidth, targetHeight, null);
        } finally {
            g2d.dispose();
        }
        return scaled;
    }

    private String sanitize(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String formatDefaultTitle(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) return "Untitled Book";
        String clean = originalFileName.replace("\\", "/");
        clean = clean.substring(clean.lastIndexOf('/') + 1);
        int dot = clean.lastIndexOf('.');
        if (dot > 0) {
            clean = clean.substring(0, dot);
        }
        return clean.replace('_', ' ').replace('-', ' ').trim();
    }
}
