-- Convert schema 'share/ddl/_source/deploy/15/001-auto.yml' to 'share/ddl/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "import_lookups" (
  "id" serial NOT NULL,
  "set_id" integer NOT NULL,
  "name" character varying(255) NOT NULL,
  "entity_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "import_lookups_idx_entity_id" on "import_lookups" ("entity_id");
CREATE INDEX "import_lookups_idx_set_id" on "import_lookups" ("set_id");

;
ALTER TABLE "import_lookups" ADD CONSTRAINT "import_lookups_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "import_lookups" ADD CONSTRAINT "import_lookups_fk_set_id" FOREIGN KEY ("set_id")
  REFERENCES "import_sets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

