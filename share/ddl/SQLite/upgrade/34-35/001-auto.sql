-- Convert schema 'share/ddl/_source/deploy/34/001-auto.yml' to 'share/ddl/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE user_topic_subscriptions (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  topic_id integer NOT NULL,
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX user_topic_subscriptions_idx_topic_id ON user_topic_subscriptions (topic_id);

;
CREATE INDEX user_topic_subscriptions_idx_user_id ON user_topic_subscriptions (user_id);

;
DROP TABLE device_subscriptions;

;

COMMIT;

