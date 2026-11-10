-- Support Google-only accounts and persist Google profile details.
-- Existing email/password accounts remain valid; password_hash stays populated for them.
ALTER TABLE users
    ALTER COLUMN password_hash DROP NOT NULL;

ALTER TABLE users
    ADD COLUMN display_name VARCHAR(100),
    ADD COLUMN profile_picture_url VARCHAR(2048),
    ADD COLUMN google_sub VARCHAR(255);

CREATE UNIQUE INDEX uq_users_google_sub
    ON users (google_sub)
    WHERE google_sub IS NOT NULL;

CREATE INDEX idx_users_email_lower
    ON users (LOWER(email));
