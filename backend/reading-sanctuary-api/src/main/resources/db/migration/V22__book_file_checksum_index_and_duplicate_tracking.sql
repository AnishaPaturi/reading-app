-- =========================================================
-- V22: Atomic Duplicate Protection & Checksum Uniqueness
-- =========================================================

-- 1. Deduplicate legacy pending uploads for the same user and checksum (keep latest)
DELETE FROM pending_book_uploads
WHERE id IN (
    SELECT p1.id
    FROM pending_book_uploads p1
    JOIN pending_book_uploads p2
      ON p1.user_id = p2.user_id
     AND p1.checksum = p2.checksum
     AND p1.created_at < p2.created_at
    WHERE p1.checksum IS NOT NULL
);

-- 2. Add user_id column to book_files if missing
ALTER TABLE book_files
    ADD COLUMN IF NOT EXISTS user_id UUID;

-- 3. Backfill user_id from books for all existing book_files
UPDATE book_files bf
SET user_id = b.created_by
FROM books b
WHERE bf.book_id = b.id
  AND bf.user_id IS NULL;

-- 4. Deduplicate legacy book_files for the same user and checksum (keep earliest imported)
DELETE FROM book_files
WHERE id IN (
    SELECT bf1.id
    FROM book_files bf1
    JOIN book_files bf2
      ON bf1.user_id = bf2.user_id
     AND bf1.checksum = bf2.checksum
     AND bf1.uploaded_at > bf2.uploaded_at
    WHERE bf1.checksum IS NOT NULL
);

-- 5. Foreign key for book_files(user_id) -> users(id)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_book_files_user'
    ) THEN
        ALTER TABLE book_files
            ADD CONSTRAINT fk_book_files_user
            FOREIGN KEY (user_id)
            REFERENCES users(id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- 6. Atomic Unique Indexes (ignoring NULL checksums)
CREATE UNIQUE INDEX IF NOT EXISTS uq_pending_user_checksum
    ON pending_book_uploads(user_id, checksum)
    WHERE checksum IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_book_files_user_checksum
    ON book_files(user_id, checksum)
    WHERE checksum IS NOT NULL;

-- 7. Performance indexes for duplicate lookup
CREATE INDEX IF NOT EXISTS idx_book_files_checksum
    ON book_files(checksum);

CREATE INDEX IF NOT EXISTS idx_book_files_book_id_checksum
    ON book_files(book_id, checksum);

CREATE INDEX IF NOT EXISTS idx_book_files_user_id
    ON book_files(user_id);
