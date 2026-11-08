package com.readingsanctuary.api.bookmetadata.service;

import java.util.List;
import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.readingsanctuary.api.bookmetadata.author.entity.Author;
import com.readingsanctuary.api.bookmetadata.author.repository.AuthorRepository;
import com.readingsanctuary.api.bookmetadata.genre.entity.Genre;
import com.readingsanctuary.api.bookmetadata.genre.repository.GenreRepository;
import com.readingsanctuary.api.bookmetadata.dto.AuthorResponse;
import com.readingsanctuary.api.bookmetadata.dto.GenreResponse;

@Service
public class ReferenceDataService {

    private final AuthorRepository authorRepository;
    private final GenreRepository genreRepository;

    public ReferenceDataService(
            AuthorRepository authorRepository,
            GenreRepository genreRepository) {

        this.authorRepository = authorRepository;
        this.genreRepository = genreRepository;
    }

    @Transactional
    public AuthorResponse createAuthor(String name, String biography) {

        String normalizedName = validateName(name);

        if (authorRepository.findByNameIgnoreCase(normalizedName).isPresent()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Author already exists");
        }

        Author author = new Author();
        author.setName(normalizedName);
        author.setBiography(biography);

        Author saved = authorRepository.save(author);

        return new AuthorResponse(
                saved.getId(), saved.getName(), saved.getBiography());
    }

    @Transactional(readOnly = true)
    public List<AuthorResponse> getAuthors() {

        return authorRepository.findAll()
                .stream()
                .map(author -> new AuthorResponse(
                        author.getId(),
                        author.getName(),
                        author.getBiography()))
                .toList();
    }

    @Transactional
    public GenreResponse createGenre(String name, String description) {

        String normalizedName = validateName(name);

        if (normalizedName.length() > 100) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Genre name is too long");
        }

        if (genreRepository.findByNameIgnoreCase(normalizedName).isPresent()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Genre already exists");
        }

        Genre genre = new Genre();
        genre.setName(normalizedName);
        genre.setDescription(description);

        Genre saved = genreRepository.save(genre);

        return new GenreResponse(
                saved.getId(), saved.getName(), saved.getDescription());
    }

    @Transactional(readOnly = true)
    public List<GenreResponse> getGenres() {

        return genreRepository.findAll()
                .stream()
                .map(genre -> new GenreResponse(
                        genre.getId(),
                        genre.getName(),
                        genre.getDescription()))
                .toList();
    }

    private String validateName(String name) {

        if (name == null || name.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Name is required");
        }

        return name.trim().replaceAll("\\s+", " ");
    }
}
