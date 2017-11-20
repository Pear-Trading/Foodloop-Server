-- Convert schema 'share/ddl/_source/deploy/13/001-auto.yml' to 'share/ddl/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "import_sets" (
  "id" serial NOT NULL,
  "date" timestamp NOT NULL,
  PRIMARY KEY ("id")
);

;
CREATE TABLE "import_values" (
  "id" serial NOT NULL,
  "set_id" integer NOT NULL,
  "user_name" character varying(255) NOT NULL,
  "purchase_date" timestamp NOT NULL,
  "purchase_value" character varying(255) NOT NULL,
  "org_name" character varying(255) NOT NULL,
  "transaction_id" character varying,
  PRIMARY KEY ("id")
);
CREATE INDEX "import_values_idx_set_id" on "import_values" ("set_id");
CREATE INDEX "import_values_idx_transaction_id" on "import_values" ("transaction_id");

;
ALTER TABLE "import_values" ADD CONSTRAINT "import_values_fk_set_id" FOREIGN KEY ("set_id")
  REFERENCES "import_sets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "import_values" ADD CONSTRAINT "import_values_fk_transaction_id" FOREIGN KEY ("transaction_id")
  REFERENCES "transactions" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

