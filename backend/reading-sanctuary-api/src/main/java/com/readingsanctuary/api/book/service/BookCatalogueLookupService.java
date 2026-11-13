package com.readingsanctuary.api.book.service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.readingsanctuary.api.book.extractor.ExtractedBookMetadata;

@Service
public class BookCatalogueLookupService {

    private static final Logger log = LoggerFactory.getLogger(BookCatalogueLookupService.class);
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    public BookCatalogueLookupService() {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(3))
                .build();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Enriches incomplete metadata using the Open Library API.
     * Never throws exceptions; falls back cleanly to the original metadata if offline or not found.
     */
    public ExtractedBookMetadata enrichMetadata(ExtractedBookMetadata original) {
        if (original == null) return ExtractedBookMetadata.empty();

        // If all core fields are already populated, no need to look up
        if (original.title() != null && original.author() != null &&
                original.description() != null && original.pages() != null && original.coverBase64() != null) {
            return original;
        }

        try {
            // 1. Try lookup by ISBN if present
            if (original.isbn() != null && !original.isbn().isBlank()) {
                String cleanIsbn = original.isbn().replaceAll("[^0-9X]", "");
                if (cleanIsbn.length() >= 10) {
                    ExtractedBookMetadata isbnResult = lookupByIsbn(cleanIsbn, original);
                    if (isbnResult != null) {
                        return isbnResult;
                    }
                }
            }

            // 2. Try lookup by Title and Author
            if (original.title() != null && !original.title().isBlank() &&
                    !original.title().equalsIgnoreCase("Untitled") &&
                    !original.title().startsWith("Untitled Book")) {

                ExtractedBookMetadata searchResult = searchByTitleAndAuthor(original.title(), original.author(), original);
                if (searchResult != null) {
                    return searchResult;
                }
            }
        } catch (Exception e) {
            log.debug("Book catalogue lookup skipped or failed: {}", e.getMessage());
        }

        return original;
    }

    private ExtractedBookMetadata lookupByIsbn(String isbn, ExtractedBookMetadata orig) {
        try {
            String url = "https://openlibrary.org/api/books?bibkeys=ISBN:" + isbn + "&format=json&jscmd=data";
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(4))
                    .header("User-Agent", "ReadingSanctuaryApp/1.0 (educational-reading-platform)")
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200 && response.body() != null && !response.body().isBlank()) {
                JsonNode root = objectMapper.readTree(response.body());
                JsonNode bookNode = root.get("ISBN:" + isbn);
                if (bookNode != null && !bookNode.isNull()) {
                    return mergeFromOpenLibrary(bookNode, orig, isbn);
                }
            }
        } catch (Exception e) {
            log.debug("ISBN lookup failed for {}: {}", isbn, e.getMessage());
        }
        return null;
    }

    private ExtractedBookMetadata searchByTitleAndAuthor(String title, String author, ExtractedBookMetadata orig) {
        try {
            StringBuilder sb = new StringBuilder("https://openlibrary.org/search.json?title=");
            sb.append(URLEncoder.encode(title, StandardCharsets.UTF_8));
            if (author != null && !author.isBlank()) {
                sb.append("&author=").append(URLEncoder.encode(author, StandardCharsets.UTF_8));
            }
            sb.append("&limit=1");

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(sb.toString()))
                    .timeout(Duration.ofSeconds(4))
                    .header("User-Agent", "ReadingSanctuaryApp/1.0 (educational-reading-platform)")
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200 && response.body() != null && !response.body().isBlank()) {
                JsonNode root = objectMapper.readTree(response.body());
                JsonNode docs = root.get("docs");
                if (docs != null && docs.isArray() && docs.size() > 0) {
                    JsonNode doc = docs.get(0);
                    return mergeFromSearchDoc(doc, orig);
                }
            }
        } catch (Exception e) {
            log.debug("Search lookup failed: {}", e.getMessage());
        }
        return null;
    }

    private ExtractedBookMetadata mergeFromOpenLibrary(JsonNode node, ExtractedBookMetadata orig, String isbn) {
        String title = orig.title();
        if (title == null || title.isBlank() || title.startsWith("Untitled")) {
            if (node.hasNonNull("title")) title = node.get("title").asText();
        }

        String author = orig.author();
        if (author == null || author.isBlank()) {
            JsonNode authors = node.get("authors");
            if (authors != null && authors.isArray() && authors.size() > 0) {
                author = authors.get(0).path("name").asText();
            }
        }

        Integer pages = orig.pages();
        if (pages == null && node.hasNonNull("number_of_pages")) {
            pages = node.get("number_of_pages").asInt();
        }

        String genre = orig.genre();
        if ((genre == null || genre.equals("Fiction") || genre.equals("Non-Fiction")) && node.has("subjects")) {
            JsonNode subjects = node.get("subjects");
            if (subjects.isArray() && subjects.size() > 0) {
                genre = subjects.get(0).path("name").asText(genre);
            }
        }

        return new ExtractedBookMetadata(
                title,
                author,
                genre,
                orig.description(),
                isbn,
                pages,
                orig.durationSeconds(),
                orig.language(),
                orig.coverBase64()
        );
    }

    private ExtractedBookMetadata mergeFromSearchDoc(JsonNode doc, ExtractedBookMetadata orig) {
        String title = orig.title();
        if (title == null || title.isBlank() || title.startsWith("Untitled")) {
            if (doc.hasNonNull("title")) title = doc.get("title").asText();
        }

        String author = orig.author();
        if (author == null || author.isBlank()) {
            JsonNode authors = doc.get("author_name");
            if (authors != null && authors.isArray() && authors.size() > 0) {
                author = authors.get(0).asText();
            }
        }

        Integer pages = orig.pages();
        if (pages == null && doc.hasNonNull("number_of_pages_median")) {
            pages = doc.get("number_of_pages_median").asInt();
        }

        String isbn = orig.isbn();
        if (isbn == null && doc.has("isbn")) {
            JsonNode isbns = doc.get("isbn");
            if (isbns.isArray() && isbns.size() > 0) {
                isbn = isbns.get(0).asText();
            }
        }

        return new ExtractedBookMetadata(
                title,
                author,
                orig.genre(),
                orig.description(),
                isbn,
                pages,
                orig.durationSeconds(),
                orig.language(),
                orig.coverBase64()
        );
    }
}
