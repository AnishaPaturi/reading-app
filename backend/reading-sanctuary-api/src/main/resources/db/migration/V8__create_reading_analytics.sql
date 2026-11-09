-- =========================================================
-- READING ACTIVITY SESSIONS
-- =========================================================

CREATE TABLE reading_activity_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,

    book_id UUID
        REFERENCES books(id) ON DELETE SET NULL,

    book_file_id UUID
        REFERENCES book_files(id) ON DELETE SET NULL,

    activity_type VARCHAR(20) NOT NULL,

    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,

    last_heartbeat_at TIMESTAMPTZ NOT NULL,

    duration_seconds INTEGER NOT NULL DEFAULT 0,

    start_progress DOUBLE PRECISION,
    end_progress DOUBLE PRECISION,

    pages_advanced INTEGER NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_activity_type
        CHECK (activity_type IN ('READING', 'AUDIOBOOK', 'TTS')),

    CONSTRAINT chk_session_duration
        CHECK (duration_seconds >= 0),

    CONSTRAINT chk_pages_advanced
        CHECK (pages_advanced >= 0),

    CONSTRAINT chk_session_end
        CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE INDEX idx_activity_user_started
    ON reading_activity_sessions(user_id, started_at DESC);

CREATE INDEX idx_activity_user_type
    ON reading_activity_sessions(user_id, activity_type);

CREATE INDEX idx_activity_book
    ON reading_activity_sessions(book_id);

CREATE INDEX idx_activity_active
    ON reading_activity_sessions(user_id, is_active)
    WHERE is_active = TRUE;


-- =========================================================
-- READING GOALS
-- =========================================================

CREATE TABLE reading_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,

    goal_type VARCHAR(30) NOT NULL,

    target_value INTEGER NOT NULL,

    period_type VARCHAR(20) NOT NULL,

    start_date DATE NOT NULL,

    end_date DATE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_goal_type
        CHECK (
            goal_type IN (
                'BOOKS_COMPLETED',
                'READING_MINUTES',
                'PAGES_READ',
                'LISTENING_MINUTES'
            )
        ),

    CONSTRAINT chk_goal_period
        CHECK (
            period_type IN ('DAILY', 'MONTHLY', 'YEARLY')
        ),

    CONSTRAINT chk_goal_target
        CHECK (target_value > 0),

    CONSTRAINT chk_goal_dates
        CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_goals_user_active
    ON reading_goals(user_id, is_active);

CREATE INDEX idx_goals_user_period
    ON reading_goals(user_id, period_type, start_date);
