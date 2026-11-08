-- V4: Bookmarks, highlights and personal book notes

CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL,
    book_file_id UUID NOT NULL,

    label VARCHAR(150),
    note TEXT,

    location_type VARCHAR(20) NOT NULL,
    location_value TEXT NOT NULL,
    page_number INTEGER,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bookmarks_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_bookmarks_file
        FOREIGN KEY (book_file_id)
        REFERENCES book_files(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_bookmark_location_type
        CHECK (location_type IN ('PDF_PAGE', 'EPUB_CFI', 'DOCX_ANCHOR')),

    CONSTRAINT chk_bookmark_page
        CHECK (page_number IS NULL OR page_number > 0)
);

CREATE INDEX idx_bookmarks_book
    ON bookmarks(book_id);

CREATE INDEX idx_bookmarks_file
    ON bookmarks(book_file_id);


CREATE TABLE book_highlights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL,
    book_file_id UUID NOT NULL,

    selected_text TEXT NOT NULL,

    location_type VARCHAR(20) NOT NULL,
    start_location TEXT NOT NULL,
    end_location TEXT NOT NULL,
    page_number INTEGER,

    color VARCHAR(20) NOT NULL DEFAULT 'YELLOW',
    annotation_note TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_highlights_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_highlights_file
        FOREIGN KEY (book_file_id)
        REFERENCES book_files(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_highlight_location_type
        CHECK (location_type IN ('PDF_PAGE', 'EPUB_CFI', 'DOCX_ANCHOR')),

    CONSTRAINT chk_highlight_color
        CHECK (color IN ('YELLOW', 'GREEN', 'BLUE', 'PINK', 'PURPLE', 'ORANGE')),

    CONSTRAINT chk_highlight_page
        CHECK (page_number IS NULL OR page_number > 0)
);

CREATE INDEX idx_highlights_book
    ON book_highlights(book_id);

CREATE INDEX idx_highlights_file
    ON book_highlights(book_file_id);


CREATE TABLE book_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL,

    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_book_notes_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_book_notes_book
    ON book_notes(book_id);
