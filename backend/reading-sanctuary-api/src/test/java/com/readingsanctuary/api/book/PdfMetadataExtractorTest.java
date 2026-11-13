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
    void extract_ValidPdf_ExtractsTitleAuthorAndPages(@TempDir File tempDir) throws IOException {
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
    }
}
