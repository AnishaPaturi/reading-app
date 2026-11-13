package com.readingsanctuary.api.book.extractor;

import java.io.File;
import java.io.IOException;

public interface BookMetadataExtractor {

    boolean supports(String fileExtension);

    ExtractedBookMetadata extract(File file, String originalFileName) throws IOException;
}
