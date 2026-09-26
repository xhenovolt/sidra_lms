-- Phase 3 enum values (own migration: new enum values cannot be used in the
-- transaction that adds them).
alter type content_block_type add value if not exists 'resource';
alter type content_block_type add value if not exists 'assignment';
alter type media_kind add value if not exists 'other';
