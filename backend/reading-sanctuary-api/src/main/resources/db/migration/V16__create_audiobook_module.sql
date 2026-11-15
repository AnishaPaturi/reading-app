-- =========================================================
-- V16: Complete Audiobook Module Schema
-- =========================================================

-- 1. AUDIOBOOKS
CREATE TABLE audiobooks (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(300),
    narrator VARCHAR(300),
    description TEXT,
    cover_path TEXT,
    folder_path TEXT,
    total_duration_ms BIGINT DEFAULT 0,
    total_tracks INTEGER DEFAULT 1,
    status VARCHAR(30) NOT NULL DEFAULT 'notStarted',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. AUDIOBOOK TRACKS
CREATE TABLE audiobook_tracks (
    id UUID PRIMARY KEY,
    audiobook_id UUID NOT NULL REFERENCES audiobooks(id) ON DELETE CASCADE,
    file_name VARCHAR(500) NOT NULL,
    track_order INTEGER NOT NULL,
    duration_ms BIGINT DEFAULT 0,
    format VARCHAR(20) NOT NULL,
    chapter_title VARCHAR(300),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(audiobook_id, track_order)
);

-- 3. AUDIOBOOK PROGRESS
CREATE TABLE audiobook_progress (
    audiobook_id UUID PRIMARY KEY REFERENCES audiobooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_track_id UUID,
    track_index INTEGER DEFAULT 0,
    position_ms BIGINT DEFAULT 0,
    total_duration_ms BIGINT DEFAULT 0,
    playback_speed NUMERIC(3,2) DEFAULT 1.00,
    completed BOOLEAN DEFAULT FALSE,
    last_listened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. AUDIOBOOK BOOKMARKS
CREATE TABLE audiobook_bookmarks (
    id UUID PRIMARY KEY,
    audiobook_id UUID NOT NULL REFERENCES audiobooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    track_id UUID,
    track_index INTEGER NOT NULL DEFAULT 0,
    position_ms BIGINT NOT NULL DEFAULT 0,
    title VARCHAR(250) NOT NULL,
    note TEXT,
    category VARCHAR(30) NOT NULL DEFAULT 'note',
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. AUDIOBOOK LISTENING SESSIONS
CREATE TABLE audiobook_listening_sessions (
    id UUID PRIMARY KEY,
    audiobook_id UUID NOT NULL REFERENCES audiobooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    actual_listening_ms BIGINT DEFAULT 0
);

-- 6. INDEXES
CREATE INDEX idx_audiobooks_user_id ON audiobooks(user_id);
CREATE INDEX idx_audiobook_tracks_audiobook_id ON audiobook_tracks(audiobook_id);
CREATE INDEX idx_audiobook_progress_user_id ON audiobook_progress(user_id);
CREATE INDEX idx_audiobook_bookmarks_user_id ON audiobook_bookmarks(user_id);
CREATE INDEX idx_audiobook_bookmarks_book_id ON audiobook_bookmarks(audiobook_id);
CREATE INDEX idx_audiobook_sessions_user_id ON audiobook_listening_sessions(user_id);
CREATE INDEX idx_audiobook_sessions_book_id ON audiobook_listening_sessions(audiobook_id);
