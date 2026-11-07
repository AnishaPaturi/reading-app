
-- =====================================================
-- READING SANCTUARY
-- Database Migration V1
-- Initial Core Tables
-- =====================================================

-- 1. USERS
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. BOOKS
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    created_by UUID NOT NULL,

    title VARCHAR(500) NOT NULL,
    description TEXT,

    language VARCHAR(50),
    publisher VARCHAR(255),

    publication_date DATE,

    isbn VARCHAR(20),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_books_user
        FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE CASCADE
);

-- 3. BOOK FILES
-- One book can have multiple ebook or audiobook files.

CREATE TABLE book_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL,

    file_name VARCHAR(500) NOT NULL,

    file_format VARCHAR(10) NOT NULL,

    storage_key VARCHAR(1000) NOT NULL UNIQUE,

    file_size_bytes BIGINT NOT NULL,

    checksum VARCHAR(128),

    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_book_files_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_book_file_format
        CHECK (file_format IN ('PDF', 'EPUB', 'DOCX', 'MP3', 'M4B')),

    CONSTRAINT chk_book_file_size
        CHECK (file_size_bytes > 0)
);

-- 4. INDEXES

CREATE INDEX idx_books_created_by
    ON books(created_by);

CREATE INDEX idx_books_title
    ON books(title);

CREATE INDEX idx_book_files_book_id
    ON book_files(book_id);

CREATE INDEX idx_users_email
    ON users(email);
