package com.readingsanctuary.api.book;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import com.readingsanctuary.api.book.extractor.DocxMetadataExtractor;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;

class DocxMetadataExtractorTest {

    private DocxMetadataExtractor extractor;

    @BeforeEach
    void setUp() {
        extractor = new DocxMetadataExtractor();
    }

    @Test
    void supports_DocxFormats() {
        assertThat(extractor.supports("docx")).isTrue();
        assertThat(extractor.supports("DOCX")).isTrue();
        assertThat(extractor.supports(" docx ")).isTrue();
        assertThat(extractor.supports("pdf")).isFalse();
        assertThat(extractor.supports("epub")).isFalse();
        assertThat(extractor.supports(null)).isFalse();
    }

    @Test
    void extract_ValidDocxWithCoreProperties_ExtractsMetadataSuccessfully(@TempDir Path tempDir) throws IOException {
        File docxFile = tempDir.resolve("sample_book.docx").toFile();

        // Create a minimal valid docx with core.xml metadata and app.xml page count
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(docxFile))) {
            // _rels/.rels
            zos.putNextEntry(new ZipEntry("_rels/.rels"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
                  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
                  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
                </Relationships>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            // [Content_Types].xml
            zos.putNextEntry(new ZipEntry("[Content_Types].xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
                  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
                  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
                </Types>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            // docProps/core.xml
            zos.putNextEntry(new ZipEntry("docProps/core.xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                                   xmlns:dc="http://purl.org/dc/elements/1.1/">
                  <dc:title>The Philosophy of Solitude</dc:title>
                  <dc:creator>Arthur Schopenhauer</dc:creator>
                  <dc:description>An essay on quiet contemplation and inner sanctuary.</dc:description>
                  <dc:language>en</dc:language>
                </cp:coreProperties>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            // docProps/app.xml
            zos.putNextEntry(new ZipEntry("docProps/app.xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
                  <Pages>42</Pages>
                  <Words>10500</Words>
                </Properties>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            // word/document.xml
            zos.putNextEntry(new ZipEntry("word/document.xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body>
                    <w:p><w:r><w:t>In the depths of winter, I finally learned that within me there lay an invincible summer.</w:t></w:r></w:p>
                  </w:body>
                </w:document>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        ExtractedBookMetadata metadata = extractor.extract(docxFile, "sample_book.docx");

        assertThat(metadata.title()).isEqualTo("The Philosophy of Solitude");
        assertThat(metadata.author()).isEqualTo("Arthur Schopenhauer");
        assertThat(metadata.description()).contains("quiet contemplation");
        assertThat(metadata.pages()).isGreaterThanOrEqualTo(1);
    }

    @Test
    void extract_DocxWithoutTitle_FallsBackToCleanFilename(@TempDir Path tempDir) throws IOException {
        File docxFile = tempDir.resolve("the_great_gatsby_notes.docx").toFile();

        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(docxFile))) {
            zos.putNextEntry(new ZipEntry("[Content_Types].xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="xml" ContentType="application/xml"/>
                </Types>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("word/document.xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body><w:p><w:r><w:t>Some document content here.</w:t></w:r></w:p></w:body>
                </w:document>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        ExtractedBookMetadata metadata = extractor.extract(docxFile, "the_great_gatsby_notes.docx");

        assertThat(metadata.title()).isEqualTo("the great gatsby notes");
    }

    @Test
    void extract_RenamedOrdinaryZip_ThrowsException(@TempDir Path tempDir) throws IOException {
        File ordinaryZip = tempDir.resolve("renamed_ordinary.docx").toFile();

        // Create standard non-DOCX zip (e.g. photos or text notes)
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(ordinaryZip))) {
            zos.putNextEntry(new ZipEntry("readme.txt"));
            zos.write("This is a plain text file inside a zip.".getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
            zos.putNextEntry(new ZipEntry("images/photo.png"));
            zos.write(new byte[]{ 0x12, 0x34, 0x56, 0x78 });
            zos.closeEntry();
        }

        assertThatThrownBy(() -> extractor.extract(ordinaryZip, "renamed_ordinary.docx"))
                .isInstanceOf(IOException.class)
                .hasMessageContaining("missing [Content_Types].xml");
    }

    @Test
    void extract_CorruptedZipArchive_ThrowsException(@TempDir Path tempDir) throws IOException {
        File corruptedFile = tempDir.resolve("corrupted.docx").toFile();

        // Write PK signature followed by corrupted/truncated bytes
        try (FileOutputStream fos = new FileOutputStream(corruptedFile)) {
            fos.write(new byte[]{ 0x50, 0x4B, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x11, 0x22 });
        }

        assertThatThrownBy(() -> extractor.extract(corruptedFile, "corrupted.docx"))
                .isInstanceOf(IOException.class)
                .hasMessageContaining("ZIP archive");
    }

    @Test
    void extract_MissingWordDocumentXml_ThrowsException(@TempDir Path tempDir) throws IOException {
        File missingDocFile = tempDir.resolve("missing_document_part.docx").toFile();

        // Has [Content_Types].xml and docProps/core.xml, but NO word/document.xml
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(missingDocFile))) {
            zos.putNextEntry(new ZipEntry("[Content_Types].xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="xml" ContentType="application/xml"/>
                </Types>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("docProps/core.xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                                   xmlns:dc="http://purl.org/dc/elements/1.1/">
                  <dc:title>Orphan Document</dc:title>
                </cp:coreProperties>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        assertThatThrownBy(() -> extractor.extract(missingDocFile, "missing_document_part.docx"))
                .isInstanceOf(IOException.class)
                .hasMessageContaining("missing word/document.xml");
    }

    @Test
    void extract_MissingContentTypesXml_ThrowsException(@TempDir Path tempDir) throws IOException {
        File missingContentTypesFile = tempDir.resolve("missing_content_types.docx").toFile();

        // Has word/document.xml, but NO [Content_Types].xml
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(missingContentTypesFile))) {
            zos.putNextEntry(new ZipEntry("word/document.xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body><w:p><w:r><w:t>Content</w:t></w:r></w:p></w:body>
                </w:document>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        assertThatThrownBy(() -> extractor.extract(missingContentTypesFile, "missing_content_types.docx"))
                .isInstanceOf(IOException.class)
                .hasMessageContaining("missing [Content_Types].xml");
    }

    @Test
    void extract_InvalidOoxmlStructure_ThrowsException(@TempDir Path tempDir) throws IOException {
        File invalidOoxmlFile = tempDir.resolve("invalid_ooxml.docx").toFile();

        // [Content_Types].xml is valid, but word/document.xml contains malformed XML syntax (unclosed tag)
        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(invalidOoxmlFile))) {
            zos.putNextEntry(new ZipEntry("[Content_Types].xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="xml" ContentType="application/xml"/>
                </Types>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("word/document.xml"));
            zos.write("""
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body>
                    <w:p><w:r><w:t>Malformed tag follows
                  </w:body>
                </w:document>
                """.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        assertThatThrownBy(() -> extractor.extract(invalidOoxmlFile, "invalid_ooxml.docx"))
                .isInstanceOf(IOException.class)
                .hasMessageContaining("Invalid OOXML structure");
    }
}
