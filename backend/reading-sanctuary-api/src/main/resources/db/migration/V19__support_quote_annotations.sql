-- =====================================================
-- V19: Support Quote Annotations
-- =====================================================

ALTER TABLE annotations DROP CONSTRAINT IF EXISTS chk_annotation_type;

ALTER TABLE annotations ADD CONSTRAINT chk_annotation_type
    CHECK (type IN ('HIGHLIGHT', 'NOTE', 'QUOTE'));
