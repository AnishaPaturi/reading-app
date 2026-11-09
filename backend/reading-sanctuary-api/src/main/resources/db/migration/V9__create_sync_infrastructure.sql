-- =========================================================
-- V9: Cloud Storage Metadata and Multi-Device Synchronization Infrastructure
-- =========================================================

-- 1. ADD CLOUD STORAGE METADATA TO BOOK FILES
ALTER TABLE book_files
    ADD COLUMN IF NOT EXISTS storage_provider VARCHAR(20) NOT NULL DEFAULT 'LOCAL',
    ADD COLUMN IF NOT EXISTS storage_status VARCHAR(30) NOT NULL DEFAULT 'LOCAL',
    ADD COLUMN IF NOT EXISTS cloud_verified_at TIMESTAMPTZ;

-- 2. SYNC DEVICES TABLE
CREATE TABLE sync_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,

    device_name VARCHAR(150) NOT NULL,

    platform VARCHAR(30) NOT NULL,

    last_sync_cursor BIGINT NOT NULL DEFAULT 0,

    last_seen_at TIMESTAMPTZ,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_devices_user
    ON sync_devices(user_id);

CREATE INDEX idx_sync_devices_user_active
    ON sync_devices(user_id, is_active);

-- 3. PER-USER CHANGE CURSORS TABLE
CREATE TABLE sync_user_cursors (
    user_id UUID PRIMARY KEY
        REFERENCES users(id) ON DELETE CASCADE,

    current_cursor BIGINT NOT NULL DEFAULT 0
);

-- 4. SYNC CHANGE LOG TABLE (Tombstones and Incremental Change Tracking)
CREATE TABLE sync_change_log (
    id BIGSERIAL PRIMARY KEY,

    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,

    cursor BIGINT NOT NULL,

    entity_type VARCHAR(50) NOT NULL,

    entity_id VARCHAR(100) NOT NULL,

    operation VARCHAR(20) NOT NULL,

    entity_version BIGINT NOT NULL DEFAULT 1,

    payload TEXT,

    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_sync_operation
        CHECK (
            operation IN ('CREATE', 'UPDATE', 'DELETE')
        )
);

CREATE INDEX idx_sync_log_user_cursor
    ON sync_change_log(user_id, cursor);

CREATE INDEX idx_sync_log_entity
    ON sync_change_log(user_id, entity_type, entity_id);

-- 5. PROCESSED CLIENT CHANGES (Idempotency deduplication)
CREATE TABLE sync_processed_changes (
    client_change_id VARCHAR(100) PRIMARY KEY,

    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,

    device_id UUID NOT NULL
        REFERENCES sync_devices(id) ON DELETE CASCADE,

    processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_processed_user
    ON sync_processed_changes(user_id);
