-- Convert schema 'share/ddl/_source/deploy/3/001-auto.yml' to 'share/ddl/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE pending_transactions ADD COLUMN purchase_time timestamp;

UPDATE pending_transactions SET purchase_time = submitted_at;

ALTER TABLE pending_transactions ALTER COLUMN purchase_time SET NOT NULL;

;

COMMIT;
