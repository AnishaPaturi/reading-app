ALTER TYPE reading_status
ADD VALUE IF NOT EXISTS 'DELETED';

ALTER TABLE books
ADD COLUMN IF NOT EXISTS previous_reading_status VARCHAR(40);

ALTER TABLE books
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_books_deleted
ON books (created_by, deleted_at DESC)
WHERE deleted_at IS NOT NULL;
