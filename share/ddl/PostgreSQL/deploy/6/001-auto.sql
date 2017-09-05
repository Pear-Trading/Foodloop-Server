-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Fri Sep  1 15:14:28 2017
-- 
;
--
-- Table: account_tokens
--
CREATE TABLE "account_tokens" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "used" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "account_tokens_name" UNIQUE ("name")
);

;
--
-- Table: entities
--
CREATE TABLE "entities" (
  "id" serial NOT NULL,
  "type" character varying(255) NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: leaderboards
--
CREATE TABLE "leaderboards" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "type" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "leaderboards_type" UNIQUE ("type")
);

;
--
-- Table: customers
--
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

;
--
-- Table: leaderboard_sets
--
CREATE TABLE "leaderboard_sets" (
  "id" serial NOT NULL,
  "leaderboard_id" integer NOT NULL,
  "date" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "leaderboard_sets_idx_leaderboard_id" on "leaderboard_sets" ("leaderboard_id");

;
--
-- Table: organisations
--
CREATE TABLE "organisations" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "name" character varying(255) NOT NULL,
  "street_name" text,
  "town" character varying(255) NOT NULL,
  "postcode" character varying(16),
  "country" character varying(255),
  "sector" character varying(1),
  "pending" boolean DEFAULT 0 NOT NULL,
  "submitted_by_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "organisations_idx_entity_id" on "organisations" ("entity_id");

;
--
-- Table: transactions
--
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

;
--
-- Table: users
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "email" text NOT NULL,
  "join_date" timestamp NOT NULL,
  "password" character varying(100) NOT NULL,
  "is_admin" boolean DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_email" UNIQUE ("email")
);
CREATE INDEX "users_idx_entity_id" on "users" ("entity_id");

;
--
-- Table: feedback
--
CREATE TABLE "feedback" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "submitted_at" timestamp NOT NULL,
  "feedbacktext" text NOT NULL,
  "app_name" character varying(255) NOT NULL,
  "package_name" character varying(255) NOT NULL,
  "version_code" character varying(255) NOT NULL,
  "version_number" character varying(255) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "feedback_idx_user_id" on "feedback" ("user_id");

;
--
-- Table: session_tokens
--
CREATE TABLE "session_tokens" (
  "id" serial NOT NULL,
  "token" character varying(255) NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "session_tokens_token" UNIQUE ("token")
);
CREATE INDEX "session_tokens_idx_user_id" on "session_tokens" ("user_id");

;
--
-- Table: leaderboard_values
--
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

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "customers" ADD CONSTRAINT "customers_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "leaderboard_sets" ADD CONSTRAINT "leaderboard_sets_fk_leaderboard_id" FOREIGN KEY ("leaderboard_id")
  REFERENCES "leaderboards" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "organisations" ADD CONSTRAINT "organisations_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_fk_buyer_id" FOREIGN KEY ("buyer_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_fk_seller_id" FOREIGN KEY ("seller_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "users" ADD CONSTRAINT "users_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "feedback" ADD CONSTRAINT "feedback_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "session_tokens" ADD CONSTRAINT "session_tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "leaderboard_values" ADD CONSTRAINT "leaderboard_values_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "leaderboard_values" ADD CONSTRAINT "leaderboard_values_fk_set_id" FOREIGN KEY ("set_id")
  REFERENCES "leaderboard_sets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;