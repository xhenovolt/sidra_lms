-- Phase 2C enum values. Kept in their own migration: PostgreSQL cannot use a
-- newly added enum value inside the transaction that added it.
alter type publish_status add value if not exists 'in_review' before 'published';
alter type content_block_type add value if not exists 'external_link';
