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
}
