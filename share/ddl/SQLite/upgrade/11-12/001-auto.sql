-- Convert schema 'share/ddl/_source/deploy/11/001-auto.yml' to 'share/ddl/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE feedback ADD COLUMN actioned boolean NOT NULL DEFAULT 0;

;

COMMIT;

