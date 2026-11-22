package com.readingsanctuary.api.book.extractor;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.util.Base64;
import java.util.Iterator;
import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.pdmodel.encryption.InvalidPasswordException;
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
    private static final long MAX_COVER_BYTES = 5L * 1024 * 1024; // 5 MB

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
        } catch (InvalidPasswordException e) {
            log.warn("PDF is password-protected for {}: {}", originalFileName, e.getMessage());
            return new ExtractedBookMetadata(
                    formatDefaultTitle(originalFileName),
                    null,
                    "Non-Fiction",
                    "Password-protected document",
                    null,
                    null,
                    null,
                    "en",
                    null
            );
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
            BufferedImage rawImage = renderer.renderImageWithDPI(0, RENDER_DPI, ImageType.RGB);
            if (rawImage == null) {
                return null;
            }

            int width = rawImage.getWidth();
            int height = rawImage.getHeight();

            double ratio = Math.min(
                    1.0,
                    Math.min(
                            (double) MAX_COVER_WIDTH / width,
                            (double) MAX_COVER_HEIGHT / height
                    )
            );

            int targetWidth = Math.max(1, (int) Math.round(width * ratio));
            int targetHeight = Math.max(1, (int) Math.round(height * ratio));

            BufferedImage cleanImage = new BufferedImage(
                    targetWidth,
                    targetHeight,
                    BufferedImage.TYPE_INT_RGB
            );

            Graphics2D g2d = cleanImage.createGraphics();
            try {
                g2d.setColor(Color.WHITE);
                g2d.fillRect(0, 0, targetWidth, targetHeight);
                g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
                g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
                g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2d.drawImage(rawImage, 0, 0, targetWidth, targetHeight, null);
            } finally {
                g2d.dispose();
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpeg");
            if (writers.hasNext()) {
                ImageWriter writer = writers.next();
                try (ImageOutputStream ios = ImageIO.createImageOutputStream(baos)) {
                    writer.setOutput(ios);
                    ImageWriteParam param = writer.getDefaultWriteParam();
                    if (param.canWriteCompressed()) {
                        param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
                        param.setCompressionQuality(0.85f);
                    }
                    writer.write(null, new IIOImage(cleanImage, null, null), param);
                } finally {
                    writer.dispose();
                }
            } else {
                boolean written = ImageIO.write(cleanImage, "jpeg", baos);
                if (!written) {
                    ImageIO.write(cleanImage, "jpg", baos);
                }
            }

            if (baos.size() > 0) {
                byte[] bytes = baos.toByteArray();
                if (bytes.length <= MAX_COVER_BYTES) {
                    return "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(bytes);
                }
            }
        } catch (Throwable t) {
            log.warn("Could not render first page of PDF as cover for {}: {}", originalFileName, t.getMessage());
        }
        return null;
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
