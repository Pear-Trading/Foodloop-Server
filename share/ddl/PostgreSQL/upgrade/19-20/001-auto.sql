-- Convert schema 'share/ddl/_source/deploy/19/001-auto.yml' to 'share/ddl/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "category" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "category_name" UNIQUE ("name")
);

;
CREATE TABLE "transaction_category" (
  "category_id" integer NOT NULL,
  "transaction_id" integer NOT NULL,
  CONSTRAINT "transaction_category_transaction_id" UNIQUE ("transaction_id")
);
CREATE INDEX "transaction_category_idx_category_id" on "transaction_category" ("category_id");
CREATE INDEX "transaction_category_idx_transaction_id" on "transaction_category" ("transaction_id");

;
ALTER TABLE "transaction_category" ADD CONSTRAINT "transaction_category_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") DEFERRABLE;

;
ALTER TABLE "transaction_category" ADD CONSTRAINT "transaction_category_fk_transaction_id" FOREIGN KEY ("transaction_id")
  REFERENCES "transactions" ("id") ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

