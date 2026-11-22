package com.readingsanctuary.api.book;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import com.readingsanctuary.api.book.extractor.EpubMetadataExtractor;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;

class EpubMetadataExtractorTest {

    private EpubMetadataExtractor extractor;

    @BeforeEach
    void setUp() {
        extractor = new EpubMetadataExtractor();
    }

    @Test
    void supports_ReturnsTrueForEpub() {
        assertThat(extractor.supports("epub")).isTrue();
        assertThat(extractor.supports("EPUB")).isTrue();
        assertThat(extractor.supports("pdf")).isFalse();
    }

    @Test
    void extract_ValidEpub_ExtractsMetadataAndCover(@TempDir File tempDir) throws IOException {
        File epubFile = new File(tempDir, "sample.epub");

        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(epubFile))) {
            // META-INF/container.xml
            zos.putNextEntry(new ZipEntry("META-INF/container.xml"));
            String containerXml = """
                    <?xml version="1.0"?>
                    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
                       <rootfiles>
                          <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
                       </rootfiles>
                    </container>
                    """;
            zos.write(containerXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            // OEBPS/content.opf
            zos.putNextEntry(new ZipEntry("OEBPS/content.opf"));
            String opfXml = """
                    <?xml version="1.0" encoding="utf-8"?>
                    <package xmlns="http://www.idpf.org/2007/opf" version="3.0">
                      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                        <dc:title>Six of Crows</dc:title>
                        <dc:creator>Leigh Bardugo</dc:creator>
                        <dc:language>en</dc:language>
                        <dc:identifier>urn:isbn:9781250076960</dc:identifier>
                        <dc:description>A fantasy heist novel.</dc:description>
                        <dc:subject>Fantasy</dc:subject>
                      </metadata>
                      <manifest>
                        <item id="cover" href="cover.jpg" media-type="image/jpeg" properties="cover-image"/>
                        <item id="chapter1" href="chap1.xhtml" media-type="application/xhtml+xml"/>
                      </manifest>
                      <spine>
                        <itemref idref="chapter1"/>
                      </spine>
                    </package>
                    """;
            zos.write(opfXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            // OEBPS/cover.jpg
            zos.putNextEntry(new ZipEntry("OEBPS/cover.jpg"));
            zos.write(new byte[]{ (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0x01, 0x02 });
            zos.closeEntry();
        }

        ExtractedBookMetadata metadata = extractor.extract(epubFile, "sample.epub");

        assertThat(metadata.title()).isEqualTo("Six of Crows");
        assertThat(metadata.author()).isEqualTo("Leigh Bardugo");
        assertThat(metadata.isbn()).contains("9781250076960");
        assertThat(metadata.language()).isEqualTo("en");
        assertThat(metadata.description()).isEqualTo("A fantasy heist novel.");
        assertThat(metadata.coverBase64()).startsWith("data:image/jpeg;base64,");
    }

    @Test
    void extract_Epub2_ExtractsCoverFromMetaTag(@TempDir File tempDir) throws IOException {
        File epubFile = new File(tempDir, "epub2.epub");

        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(epubFile))) {
            zos.putNextEntry(new ZipEntry("META-INF/container.xml"));
            String containerXml = """
                    <?xml version="1.0"?>
                    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
                       <rootfiles>
                          <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
                       </rootfiles>
                    </container>
                    """;
            zos.write(containerXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("content.opf"));
            String opfXml = """
                    <?xml version="1.0" encoding="utf-8"?>
                    <package xmlns="http://www.idpf.org/2007/opf" version="2.0">
                      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                        <dc:title>Epub 2 Classic</dc:title>
                        <dc:creator>Classic Author</dc:creator>
                        <meta name="cover" content="my-cover-image"/>
                      </metadata>
                      <manifest>
                        <item id="my-cover-image" href="images/cover.png" media-type="image/png"/>
                      </manifest>
                    </package>
                    """;
            zos.write(opfXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("images/cover.png"));
            zos.write(new byte[]{ (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });
            zos.closeEntry();
        }

        ExtractedBookMetadata metadata = extractor.extract(epubFile, "epub2.epub");

        assertThat(metadata.title()).isEqualTo("Epub 2 Classic");
        assertThat(metadata.author()).isEqualTo("Classic Author");
        assertThat(metadata.coverBase64()).startsWith("data:image/png;base64,");
    }

    @Test
    void extract_EpubWithNestedCoverAndUppercaseExt(@TempDir File tempDir) throws IOException {
        File epubFile = new File(tempDir, "nested.epub");

        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(epubFile))) {
            zos.putNextEntry(new ZipEntry("META-INF/container.xml"));
            String containerXml = """
                    <?xml version="1.0"?>
                    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
                       <rootfiles>
                          <rootfile full-path="OPS/sub/package.opf" media-type="application/oebps-package+xml"/>
                       </rootfiles>
                    </container>
                    """;
            zos.write(containerXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("OPS/sub/package.opf"));
            String opfXml = """
                    <?xml version="1.0" encoding="utf-8"?>
                    <package xmlns="http://www.idpf.org/2007/opf" version="3.0">
                      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                        <dc:title>Nested Book</dc:title>
                      </metadata>
                      <manifest>
                        <item id="cvr" href="../art/COVER.JPG" media-type="image/jpeg" properties="cover-image"/>
                      </manifest>
                    </package>
                    """;
            zos.write(opfXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("OPS/art/COVER.JPG"));
            zos.write(new byte[]{ (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0x11, 0x22 });
            zos.closeEntry();
        }

        ExtractedBookMetadata metadata = extractor.extract(epubFile, "nested.epub");

        assertThat(metadata.title()).isEqualTo("Nested Book");
        assertThat(metadata.coverBase64()).startsWith("data:image/jpeg;base64,");
    }

    @Test
    void extract_EpubWithoutCover_ReturnsNullCover(@TempDir File tempDir) throws IOException {
        File epubFile = new File(tempDir, "nocover.epub");

        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(epubFile))) {
            zos.putNextEntry(new ZipEntry("META-INF/container.xml"));
            String containerXml = """
                    <?xml version="1.0"?>
                    <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
                       <rootfiles>
                          <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
                       </rootfiles>
                    </container>
                    """;
            zos.write(containerXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new ZipEntry("OEBPS/content.opf"));
            String opfXml = """
                    <?xml version="1.0" encoding="utf-8"?>
                    <package xmlns="http://www.idpf.org/2007/opf" version="3.0">
                      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                        <dc:title>Plain Text Book</dc:title>
                      </metadata>
                      <manifest>
                        <item id="text" href="text.xhtml" media-type="application/xhtml+xml"/>
                      </manifest>
                    </package>
                    """;
            zos.write(opfXml.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        ExtractedBookMetadata metadata = extractor.extract(epubFile, "nocover.epub");

        assertThat(metadata.title()).isEqualTo("Plain Text Book");
        assertThat(metadata.coverBase64()).isNull();
    }
}
