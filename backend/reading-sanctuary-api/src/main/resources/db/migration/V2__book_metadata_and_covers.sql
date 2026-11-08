-- =========================================
-- AUTHORS TABLE
-- =========================================

CREATE TABLE authors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(255) NOT NULL,

    biography TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================
-- GENRES TABLE
-- =========================================

CREATE TABLE genres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL UNIQUE,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================
-- BOOK-AUTHOR RELATIONSHIP
-- =========================================

CREATE TABLE book_authors (
    book_id UUID NOT NULL,
    author_id UUID NOT NULL,

    PRIMARY KEY (book_id, author_id),

    CONSTRAINT fk_book_authors_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_book_authors_author
        FOREIGN KEY (author_id)
        REFERENCES authors(id)
        ON DELETE CASCADE
);


-- =========================================
-- BOOK-GENRE RELATIONSHIP
-- =========================================

CREATE TABLE book_genres (
    book_id UUID NOT NULL,
    genre_id UUID NOT NULL,

    PRIMARY KEY (book_id, genre_id),

    CONSTRAINT fk_book_genres_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_book_genres_genre
        FOREIGN KEY (genre_id)
        REFERENCES genres(id)
        ON DELETE CASCADE
);


-- =========================================
-- BOOK COVER METADATA
-- =========================================

ALTER TABLE books
ADD COLUMN cover_storage_key VARCHAR(500),
ADD COLUMN cover_file_name VARCHAR(255),
ADD COLUMN cover_content_type VARCHAR(100),
ADD COLUMN cover_updated_at TIMESTAMPTZ;
