-- Convert schema 'share/ddl/_source/deploy/32/001-auto.yml' to 'share/ddl/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "device_subscriptions" (
  "id" serial NOT NULL,
  "device_token_id" integer NOT NULL,
  "topic_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "device_subscriptions_idx_device_token_id" on "device_subscriptions" ("device_token_id");
CREATE INDEX "device_subscriptions_idx_topic_id" on "device_subscriptions" ("topic_id");

;
CREATE TABLE "topics" (
  "id" serial NOT NULL,
  "name" character varying(200) NOT NULL,
  PRIMARY KEY ("id")
);

;
ALTER TABLE "device_subscriptions" ADD CONSTRAINT "device_subscriptions_fk_device_token_id" FOREIGN KEY ("device_token_id")
  REFERENCES "device_tokens" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "device_subscriptions" ADD CONSTRAINT "device_subscriptions_fk_topic_id" FOREIGN KEY ("topic_id")
  REFERENCES "topics" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

