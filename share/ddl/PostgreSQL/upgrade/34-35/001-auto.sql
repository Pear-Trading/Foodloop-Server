-- Convert schema 'share/ddl/_source/deploy/34/001-auto.yml' to 'share/ddl/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "user_topic_subscriptions" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "topic_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_topic_subscriptions_idx_topic_id" on "user_topic_subscriptions" ("topic_id");
CREATE INDEX "user_topic_subscriptions_idx_user_id" on "user_topic_subscriptions" ("user_id");

;
ALTER TABLE "user_topic_subscriptions" ADD CONSTRAINT "user_topic_subscriptions_fk_topic_id" FOREIGN KEY ("topic_id")
  REFERENCES "topics" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "user_topic_subscriptions" ADD CONSTRAINT "user_topic_subscriptions_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

;
DROP TABLE device_subscriptions CASCADE;

;

COMMIT;

