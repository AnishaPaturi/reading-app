-- V7: TTS playback positions

CREATE TABLE tts_playback_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL,
    book_file_id UUID NOT NULL,

    chapter_index INTEGER NOT NULL DEFAULT 0,
    chunk_index INTEGER NOT NULL DEFAULT 0,
    character_offset INTEGER NOT NULL DEFAULT 0,

    progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_tts_position_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_tts_position_file
        FOREIGN KEY (book_file_id)
        REFERENCES book_files(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_tts_position_file
        UNIQUE (book_file_id),

    CONSTRAINT chk_tts_chapter
        CHECK (chapter_index >= 0),

    CONSTRAINT chk_tts_chunk
        CHECK (chunk_index >= 0),

    CONSTRAINT chk_tts_offset
        CHECK (character_offset >= 0),

    CONSTRAINT chk_tts_progress
        CHECK (progress_percentage BETWEEN 0 AND 100)
);

CREATE INDEX idx_tts_positions_book
    ON tts_playback_positions(book_id);
