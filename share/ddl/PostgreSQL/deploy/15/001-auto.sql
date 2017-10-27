-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Fri Oct 27 12:09:24 2017
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
-- Table: gb_postcodes
--
CREATE TABLE "gb_postcodes" (
  "outcode" character(4) NOT NULL,
  "incode" character(3) DEFAULT '' NOT NULL,
  "latitude" numeric(7,5),
  "longitude" numeric(7,5),
  PRIMARY KEY ("outcode", "incode")
);

;
--
-- Table: import_sets
--
CREATE TABLE "import_sets" (
  "id" serial NOT NULL,
  "date" timestamp NOT NULL,
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
  "latitude" numeric(5,2),
  "longitude" numeric(5,2),
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
  "pending" boolean DEFAULT false NOT NULL,
  "is_local" boolean,
  "submitted_by_id" integer,
  "latitude" numeric(8,5),
  "longitude" numeric(8,5),
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
  "value" numeric(100,0) NOT NULL,
  "proof_image" text,
  "submitted_at" timestamp NOT NULL,
  "purchase_time" timestamp NOT NULL,
  "distance" numeric(15),
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
  "is_admin" boolean DEFAULT false NOT NULL,
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
  "actioned" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "feedback_idx_user_id" on "feedback" ("user_id");

;
--
-- Table: organisation_payroll
--
CREATE TABLE "organisation_payroll" (
  "id" serial NOT NULL,
  "org_id" integer NOT NULL,
  "submitted_at" timestamp NOT NULL,
  "entry_period" timestamp NOT NULL,
  "employee_amount" integer NOT NULL,
  "local_employee_amount" integer NOT NULL,
  "gross_payroll" numeric(100,0) NOT NULL,
  "payroll_income_tax" numeric(100,0) NOT NULL,
  "payroll_employee_ni" numeric(100,0) NOT NULL,
  "payroll_employer_ni" numeric(100,0) NOT NULL,
  "payroll_total_pension" numeric(100,0) NOT NULL,
  "payroll_other_benefit" numeric(100,0) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "organisation_payroll_idx_org_id" on "organisation_payroll" ("org_id");

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
-- Table: import_values
--
CREATE TABLE "import_values" (
  "id" serial NOT NULL,
  "set_id" integer NOT NULL,
  "user_name" character varying(255) NOT NULL,
  "purchase_date" timestamp NOT NULL,
  "purchase_value" character varying(255) NOT NULL,
  "org_name" character varying(255) NOT NULL,
  "transaction_id" character varying,
  "ignore_value" boolean DEFAULT false NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "import_values_idx_set_id" on "import_values" ("set_id");
CREATE INDEX "import_values_idx_transaction_id" on "import_values" ("transaction_id");

;
--
-- Table: leaderboard_values
--
CREATE TABLE "leaderboard_values" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "set_id" integer NOT NULL,
  "position" integer NOT NULL,
  "value" numeric(100,0) NOT NULL,
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
ALTER TABLE "organisation_payroll" ADD CONSTRAINT "organisation_payroll_fk_org_id" FOREIGN KEY ("org_id")
  REFERENCES "organisations" ("id") DEFERRABLE;

;
ALTER TABLE "session_tokens" ADD CONSTRAINT "session_tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "import_values" ADD CONSTRAINT "import_values_fk_set_id" FOREIGN KEY ("set_id")
  REFERENCES "import_sets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "import_values" ADD CONSTRAINT "import_values_fk_transaction_id" FOREIGN KEY ("transaction_id")
  REFERENCES "transactions" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "leaderboard_values" ADD CONSTRAINT "leaderboard_values_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "leaderboard_values" ADD CONSTRAINT "leaderboard_values_fk_set_id" FOREIGN KEY ("set_id")
  REFERENCES "leaderboard_sets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
