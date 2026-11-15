-- =====================================================
-- V18: Create Persistent Annotations Table (Highlights & Notes)
-- =====================================================

CREATE TABLE IF NOT EXISTS annotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,
    book_id UUID NOT NULL,
    book_file_id UUID NOT NULL,

    type VARCHAR(20) NOT NULL,
    selected_text TEXT,
    note_text TEXT,
    color VARCHAR(30),

    page_number INTEGER,
    location_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_annotations_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_annotations_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_annotations_book_file
        FOREIGN KEY (book_file_id)
        REFERENCES book_files(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_annotation_type
        CHECK (type IN ('HIGHLIGHT', 'NOTE')),

    CONSTRAINT chk_annotation_page
        CHECK (page_number IS NULL OR page_number > 0)
);

CREATE INDEX IF NOT EXISTS idx_annotations_user_book_file
    ON annotations(user_id, book_file_id);

CREATE INDEX IF NOT EXISTS idx_annotations_book_page
    ON annotations(book_id, page_number);

CREATE INDEX IF NOT EXISTS idx_annotations_created
    ON annotations(user_id, book_file_id, created_at ASC);
