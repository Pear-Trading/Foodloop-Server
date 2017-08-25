-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Fri Aug 25 15:32:15 2017
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
-- Table: customers
--
CREATE TABLE customers (
  id INTEGER PRIMARY KEY NOT NULL,
  display_name varchar(255) NOT NULL,
  full_name varchar(255) NOT NULL,
  year_of_birth integer NOT NULL,
  postcode varchar(16) NOT NULL
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
-- Table: organisations
--
CREATE TABLE organisations (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL,
  street_name text,
  town varchar(255) NOT NULL,
  postcode varchar(16),
  sector varchar(1)
);
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
-- Table: users
--
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  customer_id integer,
  organisation_id integer,
  email text NOT NULL,
  join_date datetime NOT NULL,
  password varchar(100) NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX users_idx_customer_id ON users (customer_id);
CREATE INDEX users_idx_organisation_id ON users (organisation_id);
CREATE UNIQUE INDEX users_customer_id ON users (customer_id);
CREATE UNIQUE INDEX users_email ON users (email);
CREATE UNIQUE INDEX users_organisation_id ON users (organisation_id);
--
-- Table: administrators
--
CREATE TABLE administrators (
  user_id INTEGER PRIMARY KEY NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
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
-- Table: pending_organisations
--
CREATE TABLE pending_organisations (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL,
  street_name text,
  town varchar(255) NOT NULL,
  postcode varchar(16),
  submitted_by_id integer NOT NULL,
  submitted_at datetime NOT NULL,
  FOREIGN KEY (submitted_by_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX pending_organisations_idx_submitted_by_id ON pending_organisations (submitted_by_id);
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
-- Table: transactions
--
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value decimal(16,2) NOT NULL,
  proof_image text NOT NULL,
  submitted_at datetime NOT NULL,
  purchase_time datetime NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (seller_id) REFERENCES organisations(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX transactions_idx_buyer_id ON transactions (buyer_id);
CREATE INDEX transactions_idx_seller_id ON transactions (seller_id);
--
-- Table: pending_transactions
--
CREATE TABLE pending_transactions (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value decimal(16,2) NOT NULL,
  proof_image text NOT NULL,
  submitted_at datetime NOT NULL,
  purchase_time datetime NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (seller_id) REFERENCES pending_organisations(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX pending_transactions_idx_buyer_id ON pending_transactions (buyer_id);
CREATE INDEX pending_transactions_idx_seller_id ON pending_transactions (seller_id);
--
-- Table: leaderboard_values
--
CREATE TABLE leaderboard_values (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  set_id integer NOT NULL,
  position integer NOT NULL,
  value decimal(16,2) NOT NULL,
  trend integer NOT NULL DEFAULT 0,
  FOREIGN KEY (set_id) REFERENCES leaderboard_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX leaderboard_values_idx_set_id ON leaderboard_values (set_id);
CREATE INDEX leaderboard_values_idx_user_id ON leaderboard_values (user_id);
CREATE UNIQUE INDEX leaderboard_values_user_id_set_id ON leaderboard_values (user_id, set_id);
COMMIT;
