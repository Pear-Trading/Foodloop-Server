-- Convert schema 'share/ddl/_source/deploy/24/001-auto.yml' to 'share/ddl/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "transaction_recurring" (
  "id" serial NOT NULL,
  "transaction_id" integer NOT NULL,
  "recurring_period" character varying(255) NOT NULL,
  CONSTRAINT "transaction_recurring_transaction_id" UNIQUE ("transaction_id")
);
CREATE INDEX "transaction_recurring_idx_transaction_id" on "transaction_recurring" ("transaction_id");

;
ALTER TABLE "transaction_recurring" ADD CONSTRAINT "transaction_recurring_fk_transaction_id" FOREIGN KEY ("transaction_id")
  REFERENCES "transactions" ("id") ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

