-- Convert schema 'share/ddl/_source/deploy/12/001-auto.yml' to 'share/ddl/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE organisations ADD COLUMN is_local boolean;

;

COMMIT;

