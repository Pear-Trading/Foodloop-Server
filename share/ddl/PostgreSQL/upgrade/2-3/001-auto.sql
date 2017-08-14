-- Convert schema 'share/ddl/_source/deploy/2/001-auto.yml' to 'share/ddl/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transactions ADD COLUMN purchase_time timestamp;

UPDATE transactions SET purchase_time = submitted_at;

ALTER TABLE transactions ALTER COLUMN purchase_time SET NOT NULL;

;

COMMIT;
