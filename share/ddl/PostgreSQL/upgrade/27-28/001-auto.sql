-- Convert schema 'share/ddl/_source/deploy/27/001-auto.yml' to 'share/ddl/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "entities_postcodes" (
  "outcode" character(4) NOT NULL,
  "incode" character(3) NOT NULL,
  "entity_id" integer NOT NULL,
  PRIMARY KEY ("outcode", "incode", "entity_id")
);
CREATE INDEX "entities_postcodes_idx_entity_id" on "entities_postcodes" ("entity_id");
CREATE INDEX "entities_postcodes_idx_outcode_incode" on "entities_postcodes" ("outcode", "incode");

;
ALTER TABLE "entities_postcodes" ADD CONSTRAINT "entities_postcodes_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "entities_postcodes" ADD CONSTRAINT "entities_postcodes_fk_outcode_incode" FOREIGN KEY ("outcode", "incode")
  REFERENCES "gb_postcodes" ("outcode", "incode") DEFERRABLE;

;

COMMIT;

