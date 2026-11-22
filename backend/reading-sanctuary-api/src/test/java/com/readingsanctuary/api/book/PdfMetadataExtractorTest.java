package com.readingsanctuary.api.book;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;
import com.readingsanctuary.api.book.extractor.PdfMetadataExtractor;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.pdmodel.PDPage;

class PdfMetadataExtractorTest {

    private PdfMetadataExtractor extractor;

    @BeforeEach
    void setUp() {
        extractor = new PdfMetadataExtractor();
    }

    @Test
    void supports_ReturnsTrueForPdf() {
        assertThat(extractor.supports("pdf")).isTrue();
        assertThat(extractor.supports("PDF")).isTrue();
        assertThat(extractor.supports("epub")).isFalse();
    }

    @Test
    void extract_ValidPdf_ExtractsTitleAuthorPagesAndCover(@TempDir File tempDir) throws IOException {
        File pdfFile = new File(tempDir, "test-book.pdf");
        try (PDDocument doc = new PDDocument()) {
            doc.addPage(new PDPage());
            doc.addPage(new PDPage());
            doc.addPage(new PDPage());

            PDDocumentInformation info = new PDDocumentInformation();
            info.setTitle("The Cruel Prince");
            info.setAuthor("Holly Black");
            info.setSubject("Fantasy novel");
            doc.setDocumentInformation(info);

            doc.save(pdfFile);
        }

        ExtractedBookMetadata metadata = extractor.extract(pdfFile, "the_cruel_prince.pdf");

        assertThat(metadata.title()).isEqualTo("The Cruel Prince");
        assertThat(metadata.author()).isEqualTo("Holly Black");
        assertThat(metadata.pages()).isEqualTo(3);
        assertThat(metadata.coverBase64()).isNotNull();
        assertThat(metadata.coverBase64()).startsWith("data:image/jpeg;base64,");
    }

    @Test
    void extract_PdfWithoutMetadata_GeneratesTitleAndExtractsCover(@TempDir File tempDir) throws IOException {
        File pdfFile = new File(tempDir, "my-awesome_story.pdf");
        try (PDDocument doc = new PDDocument()) {
            doc.addPage(new PDPage());
            doc.save(pdfFile);
        }

        ExtractedBookMetadata metadata = extractor.extract(pdfFile, "my-awesome_story.pdf");

        assertThat(metadata.title()).isEqualTo("my awesome story");
        assertThat(metadata.author()).isNull();
        assertThat(metadata.pages()).isEqualTo(1);
        assertThat(metadata.coverBase64()).startsWith("data:image/jpeg;base64,");
    }

    @Test
    void extract_ZeroPagePdf_HandlesSafely(@TempDir File tempDir) throws IOException {
        File pdfFile = new File(tempDir, "empty.pdf");
        try (PDDocument doc = new PDDocument()) {
            // No pages added
            doc.save(pdfFile);
        }

        ExtractedBookMetadata metadata = extractor.extract(pdfFile, "empty.pdf");

        assertThat(metadata.title()).isEqualTo("empty");
        assertThat(metadata.pages()).isNull();
        assertThat(metadata.coverBase64()).isNull();
    }

    @Test
    void extract_PasswordProtectedPdf_HandlesGracefully(@TempDir File tempDir) throws IOException {
        File pdfFile = new File(tempDir, "protected.pdf");
        try (PDDocument doc = new PDDocument()) {
            doc.addPage(new PDPage());
            org.apache.pdfbox.pdmodel.encryption.AccessPermission ap = new org.apache.pdfbox.pdmodel.encryption.AccessPermission();
            org.apache.pdfbox.pdmodel.encryption.StandardProtectionPolicy spp =
                    new org.apache.pdfbox.pdmodel.encryption.StandardProtectionPolicy("owner123", "user123", ap);
            spp.setEncryptionKeyLength(128);
            doc.protect(spp);
            doc.save(pdfFile);
        }

        ExtractedBookMetadata metadata = extractor.extract(pdfFile, "protected.pdf");

        assertThat(metadata.title()).isEqualTo("protected");
        assertThat(metadata.coverBase64()).isNull();
    }

    @Test
    void extract_GrayscalePdf_NormalizesAndExtractsCover(@TempDir File tempDir) throws IOException {
        File pdfFile = new File(tempDir, "grayscale-doc.pdf");
        try (PDDocument doc = new PDDocument()) {
            PDPage page = new PDPage();
            doc.addPage(page);

            try (org.apache.pdfbox.pdmodel.PDPageContentStream content =
                         new org.apache.pdfbox.pdmodel.PDPageContentStream(doc, page)) {
                content.setNonStrokingColor(0.2f); // Grayscale value
                content.addRect(50, 50, 400, 600);
                content.fill();
            }

            PDDocumentInformation info = new PDDocumentInformation();
            info.setTitle("Monochrome Paper");
            doc.setDocumentInformation(info);
            doc.save(pdfFile);
        }

        ExtractedBookMetadata metadata = extractor.extract(pdfFile, "grayscale-doc.pdf");

        assertThat(metadata.title()).isEqualTo("Monochrome Paper");
        assertThat(metadata.coverBase64()).isNotNull();
        assertThat(metadata.coverBase64()).startsWith("data:image/jpeg;base64,");
    }

    @Test
    void extract_MalformedPdf_ThrowsIOException(@TempDir File tempDir) throws IOException {
        File brokenFile = new File(tempDir, "corrupted.pdf");
        try (FileOutputStream fos = new FileOutputStream(brokenFile)) {
            fos.write(new byte[]{ 0x25, 0x50, 0x44, 0x46, 0x00, 0x01, 0x02 }); // Corrupt PDF header
        }

        org.assertj.core.api.Assertions.assertThatThrownBy(() -> extractor.extract(brokenFile, "corrupted.pdf"))
                .isInstanceOf(IOException.class);
    }
}
