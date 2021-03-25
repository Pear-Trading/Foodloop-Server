-- Convert schema 'share/ddl/_source/deploy/33/001-auto.yml' to 'share/ddl/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE topics ADD COLUMN organisation_id integer;

;
CREATE INDEX topics_idx_organisation_id ON topics (organisation_id);

;

;

COMMIT;

