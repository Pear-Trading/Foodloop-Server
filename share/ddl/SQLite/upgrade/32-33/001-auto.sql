-- Convert schema 'share/ddl/_source/deploy/32/001-auto.yml' to 'share/ddl/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE device_subscriptions (
  id INTEGER PRIMARY KEY NOT NULL,
  device_token_id integer NOT NULL,
  topic_id integer NOT NULL,
  FOREIGN KEY (device_token_id) REFERENCES device_tokens(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX device_subscriptions_idx_device_token_id ON device_subscriptions (device_token_id);

;
CREATE INDEX device_subscriptions_idx_topic_id ON device_subscriptions (topic_id);

;
CREATE TABLE topics (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(200) NOT NULL
);

;

COMMIT;

