-- Convert schema 'share/ddl/_source/deploy/30/001-auto.yml' to 'share/ddl/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE device_tokens (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  token varchar(200) NOT NULL,
  register_date datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX device_tokens_idx_user_id ON device_tokens (user_id);

;

COMMIT;

