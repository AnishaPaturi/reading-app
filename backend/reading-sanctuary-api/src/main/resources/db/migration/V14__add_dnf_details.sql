-- =========================================================
-- V14: Add DNF (Did Not Finish) Retirement Details to Books
-- =========================================================

ALTER TABLE books
    ADD COLUMN IF NOT EXISTS dnf_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS dnf_reason VARCHAR(100),
    ADD COLUMN IF NOT EXISTS dnf_notes TEXT;

CREATE INDEX IF NOT EXISTS idx_books_dnf_status_at
    ON books(reading_status, dnf_at DESC)
    WHERE reading_status = 'DNF';
