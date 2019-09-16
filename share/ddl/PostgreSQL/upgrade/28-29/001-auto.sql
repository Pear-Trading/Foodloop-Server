-- Convert schema 'share/ddl/_source/deploy/28/001-auto.yml' to 'share/ddl/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "gb_wards" (
  "id" serial NOT NULL,
  "ward" character varying(100) NOT NULL,
  PRIMARY KEY ("id")
);

;
ALTER TABLE gb_postcodes ADD COLUMN ward_id integer;

;
CREATE INDEX gb_postcodes_idx_ward_id on gb_postcodes (ward_id);

;
ALTER TABLE gb_postcodes ADD CONSTRAINT gb_postcodes_fk_ward_id FOREIGN KEY (ward_id)
  REFERENCES gb_wards (id) DEFERRABLE;

;

COMMIT;

