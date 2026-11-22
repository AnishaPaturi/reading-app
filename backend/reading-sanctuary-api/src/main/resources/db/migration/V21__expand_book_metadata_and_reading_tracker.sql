-- =========================================================
-- EXPAND BOOK METADATA, STREAK FREEZES & BOOKSHELF PREFERENCES
-- Migration V21
-- =========================================================

-- 1. Additional Book Metadata Columns
ALTER TABLE books
    ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS rating_out_of_100 INTEGER,
    ADD COLUMN IF NOT EXISTS spice_rating INTEGER,
    ADD COLUMN IF NOT EXISTS mood VARCHAR(100),
    ADD COLUMN IF NOT EXISTS recommendation VARCHAR(50),
    ADD COLUMN IF NOT EXISTS purchase_price NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'INR',
    ADD COLUMN IF NOT EXISTS acquisition_method VARCHAR(50),
    ADD COLUMN IF NOT EXISTS purchase_date DATE,
    ADD COLUMN IF NOT EXISTS tropes TEXT;

-- Validation constraints
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_books_rating_100'
    ) THEN
        ALTER TABLE books
            ADD CONSTRAINT chk_books_rating_100
            CHECK (rating_out_of_100 IS NULL OR (rating_out_of_100 >= 0 AND rating_out_of_100 <= 100));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_books_spice_rating'
    ) THEN
        ALTER TABLE books
            ADD CONSTRAINT chk_books_spice_rating
            CHECK (spice_rating IS NULL OR (spice_rating >= 0 AND spice_rating <= 5));
    END IF;
END $$;

-- 2. Streak Freezes Table
CREATE TABLE IF NOT EXISTS streak_freezes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    freeze_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, freeze_date)
);

CREATE INDEX IF NOT EXISTS idx_streak_freezes_user
    ON streak_freezes(user_id, freeze_date DESC);

-- 3. Book Size Customization (for visual bookshelf resizing)
CREATE TABLE IF NOT EXISTS book_size_customizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    height_factor DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    preset_size VARCHAR(10) NOT NULL DEFAULT 'M',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, book_id)
);

CREATE INDEX IF NOT EXISTS idx_book_size_customizations_user
    ON book_size_customizations(user_id);
