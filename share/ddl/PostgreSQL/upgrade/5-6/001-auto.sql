-- Convert schema 'share/ddl/_source/deploy/5/001-auto.yml' to 'share/ddl/_source/deploy/6/001-auto.yml':;
-- Customised for proper migration

BEGIN;

CREATE TABLE "entities" (
  "id" serial NOT NULL,
  "type" character varying(255) NOT NULL,
  PRIMARY KEY ("id")
);

ALTER TABLE customers RENAME TO customers_temp;
ALTER TABLE organisations RENAME TO organisations_temp;
ALTER TABLE transactions RENAME TO transactions_temp;
ALTER TABLE users RENAME TO users_temp;

ALTER INDEX transactions_idx_buyer_id RENAME TO transactions_temp_idx_buyer_id;
ALTER INDEX transactions_idx_seller_id RENAME TO transactions_temp_idx_seller_id;

CREATE TABLE "customers" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "display_name" character varying(255) NOT NULL,
  "full_name" character varying(255) NOT NULL,
  "year_of_birth" integer NOT NULL,
  "postcode" character varying(16) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "customers_idx_entity_id" on "customers" ("entity_id");

CREATE TABLE "organisations" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "name" character varying(255) NOT NULL,
  "street_name" text,
  "town" character varying(255) NOT NULL,
  "postcode" character varying(16),
  "country" character varying(255),
  "sector" character varying(1),
  "pending" boolean DEFAULT false NOT NULL,
  "submitted_by_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "organisations_idx_entity_id" on "organisations" ("entity_id");

CREATE TABLE "transactions" (
  "id" serial NOT NULL,
  "buyer_id" integer NOT NULL,
  "seller_id" integer NOT NULL,
  "value" numeric(16,2) NOT NULL,
  "proof_image" text,
  "submitted_at" timestamp NOT NULL,
  "purchase_time" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "transactions_idx_buyer_id" on "transactions" ("buyer_id");
CREATE INDEX "transactions_idx_seller_id" on "transactions" ("seller_id");

CREATE TABLE "users" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "email" text NOT NULL,
  "join_date" timestamp NOT NULL,
  "password" character varying(100) NOT NULL,
  "is_admin" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_email" UNIQUE ("email")
);
CREATE INDEX "users_idx_entity_id" on "users" ("entity_id");

DROP TABLE leaderboard_values;
TRUNCATE TABLE leaderboard_sets;

CREATE TABLE "leaderboard_values" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "set_id" integer NOT NULL,
  "position" integer NOT NULL,
  "value" numeric(16,2) NOT NULL,
  "trend" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "leaderboard_values_entity_id_set_id" UNIQUE ("entity_id", "set_id")
);
CREATE INDEX "leaderboard_values_idx_entity_id" on "leaderboard_values" ("entity_id");
CREATE INDEX "leaderboard_values_idx_set_id" on "leaderboard_values" ("set_id");

COMMIT;

