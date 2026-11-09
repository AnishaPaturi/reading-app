-- V6: Audiobook playback positions

CREATE TABLE audiobook_playback_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    book_id UUID NOT NULL,
    book_file_id UUID NOT NULL,

    position_ms BIGINT NOT NULL DEFAULT 0,
    duration_ms BIGINT NOT NULL DEFAULT 0,

    playback_speed NUMERIC(3,2) NOT NULL DEFAULT 1.00,

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_audio_position_book
        FOREIGN KEY (book_id)
        REFERENCES books(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_audio_position_file
        FOREIGN KEY (book_file_id)
        REFERENCES book_files(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_audio_position_file
        UNIQUE (book_file_id),

    CONSTRAINT chk_audio_position
        CHECK (position_ms >= 0),

    CONSTRAINT chk_audio_duration
        CHECK (duration_ms >= 0),

    CONSTRAINT chk_audio_speed
        CHECK (playback_speed BETWEEN 0.50 AND 3.00),

    CONSTRAINT chk_audio_position_duration
        CHECK (position_ms <= duration_ms OR duration_ms = 0)
);

CREATE INDEX idx_audio_positions_book
    ON audiobook_playback_positions(book_id);
