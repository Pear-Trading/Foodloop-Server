-- Convert schema 'share/ddl/_source/deploy/6/001-auto.yml' to 'share/ddl/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE leaderboard_values_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  set_id integer NOT NULL,
  position integer NOT NULL,
  value decimal(16,2) NOT NULL,
  trend integer NOT NULL DEFAULT 0,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (set_id) REFERENCES leaderboard_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
INSERT INTO leaderboard_values_temp_alter( id, entity_id, set_id, position, value, trend) SELECT id, entity_id, set_id, position, value, trend FROM leaderboard_values;

;
DROP TABLE leaderboard_values;

;
CREATE TABLE leaderboard_values (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  set_id integer NOT NULL,
  position integer NOT NULL,
  value numeric(100,0) NOT NULL,
  trend integer NOT NULL DEFAULT 0,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (set_id) REFERENCES leaderboard_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX leaderboard_values_idx_enti00 ON leaderboard_values (entity_id);

;
CREATE INDEX leaderboard_values_idx_set_00 ON leaderboard_values (set_id);

;
CREATE UNIQUE INDEX leaderboard_values_entity_i00 ON leaderboard_values (entity_id, set_id);

;
INSERT INTO leaderboard_values SELECT id, entity_id, set_id, position, value, trend FROM leaderboard_values_temp_alter;

;
DROP TABLE leaderboard_values_temp_alter;

;
CREATE TEMPORARY TABLE transactions_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value decimal(16,2) NOT NULL,
  proof_image text,
  submitted_at datetime NOT NULL,
  purchase_time datetime NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (seller_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
INSERT INTO transactions_temp_alter( id, buyer_id, seller_id, value, proof_image, submitted_at, purchase_time) SELECT id, buyer_id, seller_id, value, proof_image, submitted_at, purchase_time FROM transactions;

;
DROP TABLE transactions;

;
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value numeric(100,0) NOT NULL,
  proof_image text,
  submitted_at datetime NOT NULL,
  purchase_time datetime NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (seller_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX transactions_idx_buyer_id02 ON transactions (buyer_id);

;
CREATE INDEX transactions_idx_seller_id02 ON transactions (seller_id);

;
INSERT INTO transactions SELECT id, buyer_id, seller_id, value * 100000, proof_image, submitted_at, purchase_time FROM transactions_temp_alter;

;
DROP TABLE transactions_temp_alter;

;

COMMIT;

