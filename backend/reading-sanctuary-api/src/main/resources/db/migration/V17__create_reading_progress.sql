-- =====================================================
-- V17: Create Persistent Reading Progress Table
-- =====================================================

CREATE TABLE IF NOT EXISTS reading_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,
    book_file_id UUID NOT NULL,

    format VARCHAR(20) NOT NULL,

    current_page INTEGER,
    total_pages INTEGER,

    chapter_href TEXT,
    epub_cfi TEXT,

    audio_position_ms BIGINT,
    audio_duration_ms BIGINT,

    progress_percentage NUMERIC(6, 3)
        NOT NULL DEFAULT 0,

    position_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    last_opened_at TIMESTAMP WITH TIME ZONE,
    client_updated_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_progress_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_progress_book_file
        FOREIGN KEY (book_file_id)
        REFERENCES book_files(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_user_book_file
        UNIQUE (user_id, book_file_id),

    CONSTRAINT chk_progress_percentage
        CHECK (
            progress_percentage >= 0
            AND progress_percentage <= 100
        )
);

CREATE INDEX IF NOT EXISTS idx_reading_progress_user
    ON reading_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_reading_progress_updated
    ON reading_progress(user_id, updated_at DESC);
