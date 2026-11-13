-- Persist optional gender attribute for users and optimize display_name lookups.
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS gender VARCHAR(20);

CREATE INDEX IF NOT EXISTS idx_users_display_name_lower
    ON users (LOWER(display_name));
