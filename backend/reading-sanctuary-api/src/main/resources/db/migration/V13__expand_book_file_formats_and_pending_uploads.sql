-- =========================================================
-- V13: Expand Book File Formats & Pending Book Uploads
-- =========================================================

-- 1. ADD DURATION SECONDS TO BOOK FILES
ALTER TABLE book_files
    ADD COLUMN IF NOT EXISTS duration_seconds BIGINT;

-- 2. ENSURE FORMAT CONSTRAINT COVERS ALL SUPPORTED FORMATS
ALTER TABLE book_files
    DROP CONSTRAINT IF EXISTS chk_book_file_format;

ALTER TABLE book_files
    ADD CONSTRAINT chk_book_file_format
    CHECK (file_format IN ('PDF', 'EPUB', 'DOCX', 'MP3', 'M4B', 'M4A'));

-- 3. PENDING BOOK UPLOADS TABLE
CREATE TABLE IF NOT EXISTS pending_book_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    file_name VARCHAR(500) NOT NULL,
    file_format VARCHAR(10) NOT NULL,
    storage_key VARCHAR(1000) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    checksum VARCHAR(128),
    title VARCHAR(500),
    author VARCHAR(255),
    genre VARCHAR(100),
    description TEXT,
    isbn VARCHAR(50),
    pages INTEGER,
    duration_seconds INTEGER,
    language VARCHAR(50),
    cover_base64 TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_pending_book_uploads_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pending_book_uploads_user
    ON pending_book_uploads(user_id);

CREATE INDEX IF NOT EXISTS idx_pending_book_uploads_expires
    ON pending_book_uploads(expires_at);
