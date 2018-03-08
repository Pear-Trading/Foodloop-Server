-- Convert schema 'share/ddl/_source/deploy/32/001-auto.yml' to 'share/ddl/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transaction_recurring ALTER COLUMN last_updated DROP NOT NULL;

;

COMMIT;

