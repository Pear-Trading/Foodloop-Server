-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Sep 13 15:24:20 2017
-- 

;
BEGIN TRANSACTION;
--
-- Table: account_tokens
--
CREATE TABLE account_tokens (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL,
  used integer NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX account_tokens_name ON account_tokens (name);
--
-- Table: entities
--
CREATE TABLE entities (
  id INTEGER PRIMARY KEY NOT NULL,
  type varchar(255) NOT NULL
);
--
-- Table: leaderboards
--
CREATE TABLE leaderboards (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL,
  type varchar(255) NOT NULL
);
CREATE UNIQUE INDEX leaderboards_type ON leaderboards (type);
--
-- Table: customers
--
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
--
-- Table: leaderboard_sets
--
CREATE TABLE leaderboard_sets (
  id INTEGER PRIMARY KEY NOT NULL,
  leaderboard_id integer NOT NULL,
  date datetime NOT NULL,
  FOREIGN KEY (leaderboard_id) REFERENCES leaderboards(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX leaderboard_sets_idx_leaderboard_id ON leaderboard_sets (leaderboard_id);
--
-- Table: organisations
--
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
--
-- Table: transactions
--
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
CREATE INDEX transactions_idx_buyer_id ON transactions (buyer_id);
CREATE INDEX transactions_idx_seller_id ON transactions (seller_id);
--
-- Table: users
--
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  email text NOT NULL,
  join_date datetime NOT NULL,
  password varchar(100) NOT NULL,
  is_admin boolean NOT NULL DEFAULT 0,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
);
CREATE INDEX users_idx_entity_id ON users (entity_id);
CREATE UNIQUE INDEX users_email ON users (email);
--
-- Table: feedback
--
CREATE TABLE feedback (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  submitted_at datetime NOT NULL,
  feedbacktext text NOT NULL,
  app_name varchar(255) NOT NULL,
  package_name varchar(255) NOT NULL,
  version_code varchar(255) NOT NULL,
  version_number varchar(255) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX feedback_idx_user_id ON feedback (user_id);
--
-- Table: session_tokens
--
CREATE TABLE session_tokens (
  id INTEGER PRIMARY KEY NOT NULL,
  token varchar(255) NOT NULL,
  user_id integer NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX session_tokens_idx_user_id ON session_tokens (user_id);
CREATE UNIQUE INDEX session_tokens_token ON session_tokens (token);
--
-- Table: leaderboard_values
--
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
CREATE INDEX leaderboard_values_idx_entity_id ON leaderboard_values (entity_id);
CREATE INDEX leaderboard_values_idx_set_id ON leaderboard_values (set_id);
CREATE UNIQUE INDEX leaderboard_values_entity_id_set_id ON leaderboard_values (entity_id, set_id);
COMMIT;
