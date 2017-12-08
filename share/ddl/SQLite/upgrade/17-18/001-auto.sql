-- Convert schema 'share/ddl/_source/deploy/17/001-auto.yml' to 'share/ddl/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE entity_association ADD COLUMN esta boolean;

;

COMMIT;

