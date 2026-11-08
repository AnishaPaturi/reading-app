-- =========================================
-- READING STATUS AND PROGRESS
-- =========================================

CREATE TYPE reading_status AS ENUM (
    'TO_READ',
    'CURRENTLY_READING',
    'COMPLETED',
    'DNF'
);

ALTER TABLE books
ADD COLUMN reading_status reading_status
    NOT NULL DEFAULT 'TO_READ',

ADD COLUMN current_page INTEGER
    NOT NULL DEFAULT 0,

ADD COLUMN total_pages INTEGER,

ADD COLUMN started_at DATE,

ADD COLUMN completed_at DATE,

ADD COLUMN last_read_at TIMESTAMPTZ;


ALTER TABLE books
ADD CONSTRAINT chk_books_current_page
CHECK (current_page >= 0);

ALTER TABLE books
ADD CONSTRAINT chk_books_total_pages
CHECK (total_pages IS NULL OR total_pages > 0);

ALTER TABLE books
ADD CONSTRAINT chk_books_page_progress
CHECK (
    total_pages IS NULL
    OR current_page <= total_pages
);

ALTER TABLE books
ADD CONSTRAINT chk_books_completion_date
CHECK (
    completed_at IS NULL
    OR started_at IS NULL
    OR completed_at >= started_at
);


-- =========================================
-- READING STATUS HISTORY
-- =========================================

CREATE TABLE book_reading_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id UUID NOT NULL,

    previous_status VARCHAR(30),

    new_status VARCHAR(30) NOT NULL,

    current_page INTEGER NOT NULL DEFAULT 0,

    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reading_history_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_reading_history_book
ON book_reading_history(book_id, changed_at DESC);


-- =========================================
-- CUSTOM BOOKSHELVES
-- =========================================

CREATE TABLE bookshelves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    name VARCHAR(100) NOT NULL,

    description TEXT,

    color VARCHAR(20),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bookshelves_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_bookshelf_user_name
        UNIQUE (user_id, name)
);


-- =========================================
-- BOOKSHELF BOOK RELATIONSHIP
-- =========================================

CREATE TABLE bookshelf_books (
    bookshelf_id UUID NOT NULL,

    book_id UUID NOT NULL,

    added_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (bookshelf_id, book_id),

    CONSTRAINT fk_bookshelf_books_shelf
        FOREIGN KEY (bookshelf_id)
        REFERENCES bookshelves(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_bookshelf_books_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE
);


-- =========================================
-- COLLECTIONS AND NESTED FOLDERS
-- =========================================

CREATE TABLE collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,

    parent_id UUID,

    name VARCHAR(100) NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_collections_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_collections_parent
        FOREIGN KEY (parent_id)
        REFERENCES collections(id)
        ON DELETE CASCADE
);


CREATE INDEX idx_collections_user
ON collections(user_id);

CREATE INDEX idx_collections_parent
ON collections(parent_id);


-- =========================================
-- COLLECTION BOOK RELATIONSHIP
-- =========================================

CREATE TABLE collection_books (
    collection_id UUID NOT NULL,

    book_id UUID NOT NULL,

    added_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (collection_id, book_id),

    CONSTRAINT fk_collection_books_collection
        FOREIGN KEY (collection_id)
        REFERENCES collections(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_collection_books_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE
);


-- =========================================
-- BOOK RATINGS AND REVIEWS
-- =========================================

CREATE TABLE book_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL UNIQUE,

    rating INTEGER,

    review TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_book_reviews_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_book_reviews_rating
        CHECK (rating IS NULL OR rating BETWEEN 1 AND 5)
);


-- =========================================
-- INDEXES
-- =========================================

CREATE INDEX idx_books_reading_status
ON books(created_by, reading_status);

CREATE INDEX idx_books_last_read
ON books(created_by, last_read_at DESC);
