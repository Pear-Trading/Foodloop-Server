-- Convert schema 'share/ddl/_source/deploy/10/001-auto.yml' to 'share/ddl/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transactions ADD COLUMN distance numeric(15);

;

COMMIT;

