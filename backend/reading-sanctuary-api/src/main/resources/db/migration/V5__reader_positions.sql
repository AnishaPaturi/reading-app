-- V5: Book reading positions

CREATE TABLE book_reading_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL,
    book_file_id UUID NOT NULL,

    location_type VARCHAR(20) NOT NULL,
    location_value TEXT NOT NULL,

    page_number INTEGER,
    total_pages INTEGER,

    progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reader_position_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_reader_position_file
        FOREIGN KEY (book_file_id)
        REFERENCES book_files(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_reader_position_file
        UNIQUE (book_file_id),

    CONSTRAINT chk_reader_position_type
        CHECK (location_type IN (
            'PDF_PAGE',
            'EPUB_CFI',
            'DOCX_ANCHOR'
        )),

    CONSTRAINT chk_reader_position_page
        CHECK (page_number IS NULL OR page_number > 0),

    CONSTRAINT chk_reader_position_total
        CHECK (total_pages IS NULL OR total_pages > 0),

    CONSTRAINT chk_reader_position_progress
        CHECK (progress_percentage BETWEEN 0 AND 100)
);

CREATE INDEX idx_reader_positions_book
    ON book_reading_positions(book_id);
