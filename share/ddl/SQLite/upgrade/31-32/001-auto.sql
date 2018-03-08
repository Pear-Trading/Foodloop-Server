-- Convert schema 'share/ddl/_source/deploy/31/001-auto.yml' to 'share/ddl/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transaction_recurring ADD COLUMN distance numeric(15);

;

COMMIT;

