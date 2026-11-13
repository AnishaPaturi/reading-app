package com.readingsanctuary.api.book.extractor;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Base64;

import org.apache.tika.metadata.Metadata;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.parser.mp3.Mp3Parser;
import org.apache.tika.sax.BodyContentHandler;
import org.jaudiotagger.audio.AudioFile;
import org.jaudiotagger.audio.AudioFileIO;
import org.jaudiotagger.audio.AudioHeader;
import org.jaudiotagger.tag.FieldKey;
import org.jaudiotagger.tag.Tag;
import org.jaudiotagger.tag.images.Artwork;
import org.springframework.stereotype.Component;

@Component
public class Mp3MetadataExtractor implements BookMetadataExtractor {

    @Override
    public boolean supports(String fileExtension) {
        return fileExtension != null && "mp3".equalsIgnoreCase(fileExtension.trim());
    }

    @Override
    public ExtractedBookMetadata extract(File file, String originalFileName) throws IOException {
        String title = null;
        String author = null;
        String album = null;
        String genre = null;
        Integer durationSeconds = null;
        String coverBase64 = null;

        // Try jaudiotagger first
        try {
            AudioFile audioFile = AudioFileIO.read(file);
            AudioHeader header = audioFile.getAudioHeader();
            if (header != null) {
                int length = header.getTrackLength();
                if (length > 0) {
                    durationSeconds = length;
                }
            }

            Tag tag = audioFile.getTag();
            if (tag != null) {
                title = sanitize(tag.getFirst(FieldKey.TITLE));
                // Audiobook author often stored in ALBUM_ARTIST or ARTIST or COMPOSER
                author = sanitize(tag.getFirst(FieldKey.ALBUM_ARTIST));
                if (author == null) {
                    author = sanitize(tag.getFirst(FieldKey.ARTIST));
                }
                if (author == null) {
                    author = sanitize(tag.getFirst(FieldKey.COMPOSER));
                }

                album = sanitize(tag.getFirst(FieldKey.ALBUM));
                genre = sanitize(tag.getFirst(FieldKey.GENRE));

                Artwork artwork = tag.getFirstArtwork();
                if (artwork != null && artwork.getBinaryData() != null) {
                    byte[] data = artwork.getBinaryData();
                    if (data.length > 0 && data.length <= 10 * 1024 * 1024) {
                        String mime = artwork.getMimeType();
                        if (mime == null || mime.isBlank()) mime = "image/jpeg";
                        coverBase64 = "data:" + mime + ";base64," + Base64.getEncoder().encodeToString(data);
                    }
                }
            }
        } catch (Exception jaudioEx) {
            // Fallback to Apache Tika for MP3 parsing
            try (InputStream in = new FileInputStream(file)) {
                Metadata metadata = new Metadata();
                Mp3Parser parser = new Mp3Parser();
                parser.parse(in, new BodyContentHandler(-1), metadata, new ParseContext());

                if (title == null) title = sanitize(metadata.get("title"));
                if (author == null) author = sanitize(metadata.get("xmpDM:artist"));
                if (author == null) author = sanitize(metadata.get("Author"));
                if (genre == null) genre = sanitize(metadata.get("xmpDM:genre"));

                String durationStr = metadata.get("xmpDM:duration");
                if (durationStr != null && durationSeconds == null) {
                    try {
                        double d = Double.parseDouble(durationStr);
                        durationSeconds = (int) Math.round(d);
                    } catch (NumberFormatException ignored) {}
                }
            } catch (Exception ignored) {}
        }

        if (title == null || title.isBlank()) {
            if (album != null && !album.isBlank()) {
                title = album;
            } else {
                title = formatDefaultTitle(originalFileName);
            }
        }

        if (genre == null || genre.isBlank()) {
            genre = "Audiobook";
        }

        return new ExtractedBookMetadata(
                title,
                author,
                genre,
                album != null ? "Album: " + album : null,
                null,
                null,
                durationSeconds,
                "en",
                coverBase64
        );
    }

    private String sanitize(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String formatDefaultTitle(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) return "Untitled Audiobook";
        String clean = originalFileName.replace("\\", "/");
        clean = clean.substring(clean.lastIndexOf('/') + 1);
        int dot = clean.lastIndexOf('.');
        if (dot > 0) clean = clean.substring(0, dot);
        return clean.replace('_', ' ').replace('-', ' ').trim();
    }
}
