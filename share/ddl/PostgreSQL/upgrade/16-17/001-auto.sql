-- Convert schema 'share/ddl/_source/deploy/16/001-auto.yml' to 'share/ddl/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "entity_association" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "lis" boolean,
  PRIMARY KEY ("id")
);
CREATE INDEX "entity_association_idx_entity_id" on "entity_association" ("entity_id");

;
ALTER TABLE "entity_association" ADD CONSTRAINT "entity_association_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE import_values ALTER COLUMN transaction_id TYPE integer;

;

COMMIT;

