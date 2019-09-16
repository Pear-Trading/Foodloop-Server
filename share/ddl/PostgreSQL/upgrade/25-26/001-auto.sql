-- Convert schema 'share/ddl/_source/deploy/25/001-auto.yml' to 'share/ddl/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "external_references" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "external_references_name" UNIQUE ("name")
);

;
CREATE TABLE "organisation_social_types" (
  "id" serial NOT NULL,
  "key" character varying(255) NOT NULL,
  "name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "organisation_social_types_key" UNIQUE ("key")
);

;
CREATE TABLE "organisation_types" (
  "id" serial NOT NULL,
  "key" character varying(255) NOT NULL,
  "name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "organisation_types_key" UNIQUE ("key")
);

;
CREATE TABLE "organisations_external" (
  "id" serial NOT NULL,
  "org_id" integer NOT NULL,
  "external_reference_id" integer NOT NULL,
  "external_id" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "organisations_external_external_reference_id_external_id" UNIQUE ("external_reference_id", "external_id")
);
CREATE INDEX "organisations_external_idx_external_reference_id" on "organisations_external" ("external_reference_id");
CREATE INDEX "organisations_external_idx_org_id" on "organisations_external" ("org_id");

;
CREATE TABLE "transactions_external" (
  "id" serial NOT NULL,
  "transaction_id" integer NOT NULL,
  "external_reference_id" integer NOT NULL,
  "external_id" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "transactions_external_external_reference_id_external_id" UNIQUE ("external_reference_id", "external_id")
);
CREATE INDEX "transactions_external_idx_external_reference_id" on "transactions_external" ("external_reference_id");
CREATE INDEX "transactions_external_idx_transaction_id" on "transactions_external" ("transaction_id");

;
ALTER TABLE "organisations_external" ADD CONSTRAINT "organisations_external_fk_external_reference_id" FOREIGN KEY ("external_reference_id")
  REFERENCES "external_references" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "organisations_external" ADD CONSTRAINT "organisations_external_fk_org_id" FOREIGN KEY ("org_id")
  REFERENCES "organisations" ("id") DEFERRABLE;

;
ALTER TABLE "transactions_external" ADD CONSTRAINT "transactions_external_fk_external_reference_id" FOREIGN KEY ("external_reference_id")
  REFERENCES "external_references" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "transactions_external" ADD CONSTRAINT "transactions_external_fk_transaction_id" FOREIGN KEY ("transaction_id")
  REFERENCES "transactions" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE organisations ADD COLUMN type_id integer;

;
ALTER TABLE organisations ADD COLUMN social_type_id integer;

;
ALTER TABLE organisations ADD COLUMN is_anchor boolean DEFAULT FALSE NOT NULL;

;
CREATE INDEX organisations_idx_type_id on organisations (type_id);

;
CREATE INDEX organisations_idx_social_type_id on organisations (social_type_id);

;
ALTER TABLE organisations ADD CONSTRAINT organisations_fk_type_id FOREIGN KEY (type_id)
  REFERENCES organisation_types (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE organisations ADD CONSTRAINT organisations_fk_social_type_id FOREIGN KEY (social_type_id)
  REFERENCES organisation_types (id) DEFERRABLE;

;

COMMIT;

