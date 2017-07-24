-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Jul 24 15:29:45 2017
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
-- Table: customers
--
CREATE TABLE "customers" (
  "id" serial NOT NULL,
  "display_name" character varying(255) NOT NULL,
  "full_name" character varying(255) NOT NULL,
  "year_of_birth" integer NOT NULL,
  "postcode" character varying(16) NOT NULL,
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
-- Table: organisations
--
CREATE TABLE "organisations" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "street_name" text,
  "town" character varying(255) NOT NULL,
  "postcode" character varying(16),
  PRIMARY KEY ("id")
);

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
-- Table: users
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "customer_id" integer,
  "organisation_id" integer,
  "email" text NOT NULL,
  "join_date" timestamp NOT NULL,
  "password" character varying(100) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_customer_id" UNIQUE ("customer_id"),
  CONSTRAINT "users_email" UNIQUE ("email"),
  CONSTRAINT "users_organisation_id" UNIQUE ("organisation_id")
);
CREATE INDEX "users_idx_customer_id" on "users" ("customer_id");
CREATE INDEX "users_idx_organisation_id" on "users" ("organisation_id");

;
--
-- Table: administrators
--
CREATE TABLE "administrators" (
  "user_id" integer NOT NULL,
  PRIMARY KEY ("user_id")
);

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
-- Table: pending_organisations
--
CREATE TABLE "pending_organisations" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "street_name" text,
  "town" character varying(255) NOT NULL,
  "postcode" character varying(16),
  "submitted_by_id" integer NOT NULL,
  "submitted_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "pending_organisations_idx_submitted_by_id" on "pending_organisations" ("submitted_by_id");

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
-- Table: transactions
--
CREATE TABLE "transactions" (
  "id" serial NOT NULL,
  "buyer_id" integer NOT NULL,
  "seller_id" integer NOT NULL,
  "value" numeric(16,2) NOT NULL,
  "proof_image" text NOT NULL,
  "submitted_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "transactions_idx_buyer_id" on "transactions" ("buyer_id");
CREATE INDEX "transactions_idx_seller_id" on "transactions" ("seller_id");

;
--
-- Table: pending_transactions
--
CREATE TABLE "pending_transactions" (
  "id" serial NOT NULL,
  "buyer_id" integer NOT NULL,
  "seller_id" integer NOT NULL,
  "value" numeric(16,2) NOT NULL,
  "proof_image" text NOT NULL,
  "submitted_at" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "pending_transactions_idx_buyer_id" on "pending_transactions" ("buyer_id");
CREATE INDEX "pending_transactions_idx_seller_id" on "pending_transactions" ("seller_id");

;
--
-- Table: leaderboard_values
--
CREATE TABLE "leaderboard_values" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "set_id" integer NOT NULL,
  "position" integer NOT NULL,
  "value" numeric(16,2) NOT NULL,
  "trend" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "leaderboard_values_user_id_set_id" UNIQUE ("user_id", "set_id")
);
CREATE INDEX "leaderboard_values_idx_set_id" on "leaderboard_values" ("set_id");
CREATE INDEX "leaderboard_values_idx_user_id" on "leaderboard_values" ("user_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "leaderboard_sets" ADD CONSTRAINT "leaderboard_sets_fk_leaderboard_id" FOREIGN KEY ("leaderboard_id")
  REFERENCES "leaderboards" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "users" ADD CONSTRAINT "users_fk_customer_id" FOREIGN KEY ("customer_id")
  REFERENCES "customers" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "users" ADD CONSTRAINT "users_fk_organisation_id" FOREIGN KEY ("organisation_id")
  REFERENCES "organisations" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "administrators" ADD CONSTRAINT "administrators_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "feedback" ADD CONSTRAINT "feedback_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "pending_organisations" ADD CONSTRAINT "pending_organisations_fk_submitted_by_id" FOREIGN KEY ("submitted_by_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "session_tokens" ADD CONSTRAINT "session_tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_fk_buyer_id" FOREIGN KEY ("buyer_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_fk_seller_id" FOREIGN KEY ("seller_id")
  REFERENCES "organisations" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "pending_transactions" ADD CONSTRAINT "pending_transactions_fk_buyer_id" FOREIGN KEY ("buyer_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "pending_transactions" ADD CONSTRAINT "pending_transactions_fk_seller_id" FOREIGN KEY ("seller_id")
  REFERENCES "pending_organisations" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "leaderboard_values" ADD CONSTRAINT "leaderboard_values_fk_set_id" FOREIGN KEY ("set_id")
  REFERENCES "leaderboard_sets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "leaderboard_values" ADD CONSTRAINT "leaderboard_values_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
