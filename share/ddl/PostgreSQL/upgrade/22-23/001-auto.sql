-- Convert schema 'share/ddl/_source/deploy/22/001-auto.yml' to 'share/ddl/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "global_medal_group" (
  "id" serial NOT NULL,
  "group_name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "global_medal_group_group_name" UNIQUE ("group_name")
);

;
CREATE TABLE "global_medals" (
  "id" serial NOT NULL,
  "group_id" integer NOT NULL,
  "threshold" integer NOT NULL,
  "points" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "global_medals_idx_group_id" on "global_medals" ("group_id");

;
CREATE TABLE "global_user_medal_progress" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  "total" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "global_user_medal_progress_idx_entity_id" on "global_user_medal_progress" ("entity_id");
CREATE INDEX "global_user_medal_progress_idx_group_id" on "global_user_medal_progress" ("group_id");

;
CREATE TABLE "global_user_medals" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  "points" integer NOT NULL,
  "awarded_at" timestamp NOT NULL,
  "threshold" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "global_user_medals_idx_entity_id" on "global_user_medals" ("entity_id");
CREATE INDEX "global_user_medals_idx_group_id" on "global_user_medals" ("group_id");

;
CREATE TABLE "org_medal_group" (
  "id" serial NOT NULL,
  "group_name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "org_medal_group_group_name" UNIQUE ("group_name")
);

;
CREATE TABLE "org_medals" (
  "id" serial NOT NULL,
  "group_id" integer NOT NULL,
  "threshold" integer NOT NULL,
  "points" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "org_medals_idx_group_id" on "org_medals" ("group_id");

;
CREATE TABLE "org_user_medal_progress" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  "total" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "org_user_medal_progress_idx_entity_id" on "org_user_medal_progress" ("entity_id");
CREATE INDEX "org_user_medal_progress_idx_group_id" on "org_user_medal_progress" ("group_id");

;
CREATE TABLE "org_user_medals" (
  "id" serial NOT NULL,
  "entity_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  "points" integer NOT NULL,
  "awarded_at" timestamp NOT NULL,
  "threshold" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "org_user_medals_idx_entity_id" on "org_user_medals" ("entity_id");
CREATE INDEX "org_user_medals_idx_group_id" on "org_user_medals" ("group_id");

;
CREATE TABLE "transaction_recurring" (
  "id" serial NOT NULL,
  "buyer_id" integer NOT NULL,
  "seller_id" integer NOT NULL,
  "value" numeric(100,0) NOT NULL,
  "start_time" timestamp NOT NULL,
  "last_updated" timestamp,
  "essential" boolean DEFAULT false NOT NULL,
  "distance" numeric(15),
  "category_id" integer,
  "recurring_period" character varying(255) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "transaction_recurring_idx_buyer_id" on "transaction_recurring" ("buyer_id");
CREATE INDEX "transaction_recurring_idx_category_id" on "transaction_recurring" ("category_id");
CREATE INDEX "transaction_recurring_idx_seller_id" on "transaction_recurring" ("seller_id");

;
ALTER TABLE "global_medals" ADD CONSTRAINT "global_medals_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "global_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

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
ALTER TABLE "org_medals" ADD CONSTRAINT "org_medals_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "org_medal_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

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
ALTER TABLE "transaction_recurring" ADD CONSTRAINT "transaction_recurring_fk_buyer_id" FOREIGN KEY ("buyer_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "transaction_recurring" ADD CONSTRAINT "transaction_recurring_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") DEFERRABLE;

;
ALTER TABLE "transaction_recurring" ADD CONSTRAINT "transaction_recurring_fk_seller_id" FOREIGN KEY ("seller_id")
  REFERENCES "entities" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE transactions ADD COLUMN essential boolean DEFAULT false NOT NULL;

;

COMMIT;

