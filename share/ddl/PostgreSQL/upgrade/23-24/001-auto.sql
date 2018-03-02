-- Convert schema 'share/ddl/_source/deploy/23/001-auto.yml' to 'share/ddl/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transactions ADD COLUMN essential boolean DEFAULT false NOT NULL;

;

COMMIT;

