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
  "group_id" character varying(255) NOT NULL,
  "threshold" integer NOT NULL,
  "points" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "global_medals_idx_group_id" on "global_medals" ("group_id");

;
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
CREATE TABLE "org_medal_group" (
  "id" serial NOT NULL,
  "group_name" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "org_medal_group_group_name" UNIQUE ("group_name")
);

;
CREATE TABLE "org_medals" (
  "id" serial NOT NULL,
  "group_id" character varying(255) NOT NULL,
  "threshold" integer NOT NULL,
  "points" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "org_medals_idx_group_id" on "org_medals" ("group_id");

;
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

COMMIT;

