-- Convert schema 'share/ddl/_source/deploy/5/001-auto.yml' to 'share/ddl/_source/deploy/6/001-auto.yml':;
-- Customised for proper migration

BEGIN;

CREATE TABLE entities (
  id INTEGER PRIMARY KEY NOT NULL,
  type varchar(255) NOT NULL
);

ALTER TABLE customers RENAME TO customers_temp;

CREATE TABLE customers (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  display_name varchar(255) NOT NULL,
  full_name varchar(255) NOT NULL,
  year_of_birth integer NOT NULL,
  postcode varchar(16) NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
);
CREATE INDEX customers_idx_entity_id ON customers (entity_id);

-- Leaderboards must be regenerated, this saves trying to do this the hard way
DROP TABLE leaderboard_values;
DELETE FROM leaderboard_sets;

CREATE TABLE leaderboard_values (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  set_id integer NOT NULL,
  position integer NOT NULL,
  value decimal(16,2) NOT NULL,
  trend integer NOT NULL DEFAULT 0,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (set_id) REFERENCES leaderboard_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX leaderboard_values_idx_entity_id ON leaderboard_values (entity_id);
CREATE INDEX leaderboard_values_idx_set_id ON leaderboard_values (set_id);
CREATE UNIQUE INDEX leaderboard_values_entity_id_set_id ON leaderboard_values (entity_id, set_id);

ALTER TABLE organisations RENAME TO organisations_temp;

CREATE TABLE organisations (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  name varchar(255) NOT NULL,
  street_name text,
  town varchar(255) NOT NULL,
  postcode varchar(16),
  country varchar(255),
  sector varchar(1),
  pending boolean NOT NULL DEFAULT 0,
  submitted_by_id integer,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
);
CREATE INDEX organisations_idx_entity_id ON organisations (entity_id);

ALTER TABLE transactions RENAME TO transactions_temp;

CREATE TABLE transactions (
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
CREATE INDEX transactions_idx_buyer_id02 ON transactions (buyer_id);
CREATE INDEX transactions_idx_seller_id02 ON transactions (seller_id);

ALTER TABLE users RENAME TO users_temp;

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  email text NOT NULL,
  join_date datetime NOT NULL,
  password varchar(100) NOT NULL,
  is_admin boolean NOT NULL DEFAULT 0,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
);
CREATE INDEX users_idx_entity_id02 ON users (entity_id);
CREATE UNIQUE INDEX users_email02 ON users (email);

COMMIT;

