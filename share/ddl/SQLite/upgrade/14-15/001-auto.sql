-- Convert schema 'share/ddl/_source/deploy/14/001-auto.yml' to 'share/ddl/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE import_values ADD COLUMN ignore_value boolean NOT NULL DEFAULT 0;

;

COMMIT;

