-- Convert schema 'share/ddl/_source/deploy/30/001-auto.yml' to 'share/ddl/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "device_tokens" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "token" character varying(200) NOT NULL,
  "register_date" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "device_tokens_idx_user_id" on "device_tokens" ("user_id");

;
ALTER TABLE "device_tokens" ADD CONSTRAINT "device_tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

