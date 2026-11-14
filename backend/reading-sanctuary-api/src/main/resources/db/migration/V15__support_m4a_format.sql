-- =========================================================
-- V15: Support M4A Format in Book Files
-- =========================================================

ALTER TABLE book_files
    DROP CONSTRAINT IF EXISTS chk_book_file_format;

ALTER TABLE book_files
    ADD CONSTRAINT chk_book_file_format
    CHECK (file_format IN ('PDF', 'EPUB', 'DOCX', 'MP3', 'M4B', 'M4A'));
