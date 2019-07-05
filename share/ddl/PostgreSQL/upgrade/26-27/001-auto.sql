-- Convert schema 'share/ddl/_source/deploy/26/001-auto.yml' to 'share/ddl/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE organisations DROP CONSTRAINT organisations_fk_social_type_id;

;
ALTER TABLE organisations ADD CONSTRAINT organisations_fk_social_type_id FOREIGN KEY (social_type_id)
  REFERENCES organisation_social_types (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE organisations_external DROP CONSTRAINT organisations_external_fk_org_id;

;
ALTER TABLE organisations_external ADD CONSTRAINT organisations_external_fk_org_id FOREIGN KEY (org_id)
  REFERENCES organisations (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

