-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Thu Mar  8 13:11:17 2018
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
-- Table: category
--
CREATE TABLE "category" (
  "id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "category_name" UNIQUE ("name")
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
-- Table: global_medal_group
--
CREATE TABLE "global_medal_group" (
  "id" serial NOT NULL,
  "group_name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "global_medal_group_group_name" UNIQUE ("group_name")
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
-- Table: org_medal_group
--
CREATE TABLE "org_medal_group" (
  "id" serial NOT NULL,
  "group_name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "org_medal_group_group_name" UNIQUE ("group_name")
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
-- Table: entity_association
--
CREATE TABLE "entity_association" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "lis" boolean,
  "esta" boolean,
  PRIMARY KEY ("id")
);
CREATE INDEX "entity_association_idx_entity_id" on "entity_association" ("entity_id");

;
--
-- Table: global_medals
--
CREATE TABLE "global_medals" (
  "id" serial NOT NULL,
  "group_id" character varying(255) NOT NULL,
  "threshold" integer NOT NULL,
  "points" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "global_medals_idx_group_id" on "global_medals" ("group_id");

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
-- Table: org_medals
--
CREATE TABLE "org_medals" (
  "id" serial NOT NULL,
  "group_id" character varying(255) NOT NULL,
  "threshold" integer NOT NULL,
  "points" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "org_medals_idx_group_id" on "org_medals" ("group_id");

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
  "is_fair" boolean,
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
  "essential" boolean DEFAULT false NOT NULL,
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
-- Table: global_user_medal_progress
--
CREATE TABLE "global_user_medal_progress" (
  "id" serial NOT NULL,
  "entity_id" character varying(255) NOT NULL,
  "group_id" character varying(255) NOT NULL,
  "total" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "global_user_medal_progress_idx_entity_id" on "global_user_medal_progress" ("entity_id");
CREATE INDEX "global_user_medal_progress_idx_group_id" on "global_user_medal_progress" ("group_id");

;
--
-- Table: global_user_medals
--
CREATE TABLE "global_user_medals" (
  "id" serial NOT NULL,
  "entity_id" character varying(255) NOT NULL,
  "group_id" character varying(255) NOT NULL,
  "points" integer NOT NULL,
  "awarded_at" timestamp NOT NULL,
  "threshold" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "global_user_medals_idx_entity_id" on "global_user_medals" ("entity_id");
CREATE INDEX "global_user_medals_idx_group_id" on "global_user_medals" ("group_id");

;
--
-- Table: import_lookups
--
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
--
-- Table: org_user_medal_progress
--
CREATE TABLE "org_user_medal_progress" (
  "id" serial NOT NULL,
  "entity_id" character varying(255) NOT NULL,
  "group_id" character varying(255) NOT NULL,
  "total" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "org_user_medal_progress_idx_entity_id" on "org_user_medal_progress" ("entity_id");
CREATE INDEX "org_user_medal_progress_idx_group_id" on "org_user_medal_progress" ("group_id");

;
--
-- Table: org_user_medals
--
CREATE TABLE "org_user_medals" (
  "id" serial NOT NULL,
  "entity_id" character varying(255) NOT NULL,
  "group_id" character varying(255) NOT NULL,
  "points" integer NOT NULL,
  "awarded_at" timestamp NOT NULL,
  "threshold" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "org_user_medals_idx_entity_id" on "org_user_medals" ("entity_id");
CREATE INDEX "org_user_medals_idx_group_id" on "org_user_medals" ("group_id");

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
-- Table: transaction_recurring
--
CREATE TABLE "transaction_recurring" (
  "id" serial NOT NULL,
  "buyer_id" integer NOT NULL,
  "seller_id" integer NOT NULL,
  "value" numeric(100,0) NOT NULL,
  "start_time" timestamp NOT NULL,
  "last_updated" timestamp NOT NULL,
  "essential" boolean DEFAULT false NOT NULL,
  "category_id" integer,
  "recurring_period" character varying(255) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "transaction_recurring_idx_buyer_id" on "transaction_recurring" ("buyer_id");
CREATE INDEX "transaction_recurring_idx_category_id" on "transaction_recurring" ("category_id");
CREATE INDEX "transaction_recurring_idx_seller_id" on "transaction_recurring" ("seller_id");

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
  "transaction_id" integer,
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
-- Table: transaction_category
--
CREATE TABLE "transaction_category" (
  "category_id" integer NOT NULL,
  "transaction_id" integer NOT NULL,
  CONSTRAINT "transaction_category_transaction_id" UNIQUE ("transaction_id")
);
CREATE INDEX "transaction_category_idx_category_id" on "transaction_category" ("category_id");
CREATE INDEX "transaction_category_idx_transaction_id" on "transaction_category" ("transaction_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "customers" ADD CONSTRAINT "customers_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "entity_association" ADD CONSTRAINT "entity_association_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "global_medals" ADD CONSTRAINT "global_medals_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "global_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "leaderboard_sets" ADD CONSTRAINT "leaderboard_sets_fk_leaderboard_id" FOREIGN KEY ("leaderboard_id")
  REFERENCES "leaderboards" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "org_medals" ADD CONSTRAINT "org_medals_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "org_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

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
ALTER TABLE "global_user_medal_progress" ADD CONSTRAINT "global_user_medal_progress_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") DEFERRABLE;

;
ALTER TABLE "global_user_medal_progress" ADD CONSTRAINT "global_user_medal_progress_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "global_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "global_user_medals" ADD CONSTRAINT "global_user_medals_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") DEFERRABLE;

;
ALTER TABLE "global_user_medals" ADD CONSTRAINT "global_user_medals_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "global_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "import_lookups" ADD CONSTRAINT "import_lookups_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "import_lookups" ADD CONSTRAINT "import_lookups_fk_set_id" FOREIGN KEY ("set_id")
  REFERENCES "import_sets" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "org_user_medal_progress" ADD CONSTRAINT "org_user_medal_progress_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") DEFERRABLE;

;
ALTER TABLE "org_user_medal_progress" ADD CONSTRAINT "org_user_medal_progress_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "org_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "org_user_medals" ADD CONSTRAINT "org_user_medals_fk_entity_id" FOREIGN KEY ("entity_id")
  REFERENCES "entities" ("id") DEFERRABLE;

;
ALTER TABLE "org_user_medals" ADD CONSTRAINT "org_user_medals_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "org_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "organisation_payroll" ADD CONSTRAINT "organisation_payroll_fk_org_id" FOREIGN KEY ("org_id")
  REFERENCES "organisations" ("id") DEFERRABLE;

;
ALTER TABLE "session_tokens" ADD CONSTRAINT "session_tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "transaction_recurring" ADD CONSTRAINT "transaction_recurring_fk_buyer_id" FOREIGN KEY ("buyer_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "transaction_recurring" ADD CONSTRAINT "transaction_recurring_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") DEFERRABLE;

;
ALTER TABLE "transaction_recurring" ADD CONSTRAINT "transaction_recurring_fk_seller_id" FOREIGN KEY ("seller_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

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
ALTER TABLE "transaction_category" ADD CONSTRAINT "transaction_category_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "transaction_category" ADD CONSTRAINT "transaction_category_fk_transaction_id" FOREIGN KEY ("transaction_id")
  REFERENCES "transactions" ("id") ON DELETE CASCADE DEFERRABLE;

;
