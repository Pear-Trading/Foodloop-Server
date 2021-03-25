-- Convert schema 'share/ddl/_source/deploy/33/001-auto.yml' to 'share/ddl/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE topics ADD COLUMN organisation_id integer;

;
CREATE INDEX topics_idx_organisation_id on topics (organisation_id);

;
ALTER TABLE topics ADD CONSTRAINT topics_fk_organisation_id FOREIGN KEY (organisation_id)
  REFERENCES organisations (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

