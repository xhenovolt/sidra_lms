-- 0043 A newer attempt can supersede one still waiting (used by 0044).
-- On its own because Postgres won't let a new enum value be used in the
-- transaction that adds it. Nothing uses it until 0044.
alter type submission_status add value if not exists 'superseded';
