-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Jan 16 12:53:24 2018
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
-- Table: category
--
CREATE TABLE category (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL
);
CREATE UNIQUE INDEX category_name ON category (name);
--
-- Table: entities
--
CREATE TABLE entities (
  id INTEGER PRIMARY KEY NOT NULL,
  type varchar(255) NOT NULL
);
--
-- Table: gb_postcodes
--
CREATE TABLE gb_postcodes (
  outcode char(4) NOT NULL,
  incode char(3) NOT NULL DEFAULT '',
  latitude decimal(7,5),
  longitude decimal(7,5),
  PRIMARY KEY (outcode, incode)
);
--
-- Table: import_sets
--
CREATE TABLE import_sets (
  id INTEGER PRIMARY KEY NOT NULL,
  date datetime NOT NULL
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
  latitude decimal(5,2),
  longitude decimal(5,2),
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
);
CREATE INDEX customers_idx_entity_id ON customers (entity_id);
--
-- Table: entity_association
--
CREATE TABLE entity_association (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  lis boolean,
  esta boolean,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
);
CREATE INDEX entity_association_idx_entity_id ON entity_association (entity_id);
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
  pending boolean NOT NULL DEFAULT false,
  is_local boolean,
  is_fair boolean,
  submitted_by_id integer,
  latitude decimal(8,5),
  longitude decimal(8,5),
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
  distance numeric(15),
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
  is_admin boolean NOT NULL DEFAULT false,
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
  actioned boolean NOT NULL DEFAULT false,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX feedback_idx_user_id ON feedback (user_id);
--
-- Table: import_lookups
--
CREATE TABLE import_lookups (
  id INTEGER PRIMARY KEY NOT NULL,
  set_id integer NOT NULL,
  name varchar(255) NOT NULL,
  entity_id integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (set_id) REFERENCES import_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX import_lookups_idx_entity_id ON import_lookups (entity_id);
CREATE INDEX import_lookups_idx_set_id ON import_lookups (set_id);
--
-- Table: organisation_payroll
--
CREATE TABLE organisation_payroll (
  id INTEGER PRIMARY KEY NOT NULL,
  org_id integer NOT NULL,
  submitted_at datetime NOT NULL,
  entry_period datetime NOT NULL,
  employee_amount integer NOT NULL,
  local_employee_amount integer NOT NULL,
  gross_payroll numeric(100,0) NOT NULL,
  payroll_income_tax numeric(100,0) NOT NULL,
  payroll_employee_ni numeric(100,0) NOT NULL,
  payroll_employer_ni numeric(100,0) NOT NULL,
  payroll_total_pension numeric(100,0) NOT NULL,
  payroll_other_benefit numeric(100,0) NOT NULL,
  FOREIGN KEY (org_id) REFERENCES organisations(id)
);
CREATE INDEX organisation_payroll_idx_org_id ON organisation_payroll (org_id);
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
-- Table: import_values
--
CREATE TABLE import_values (
  id INTEGER PRIMARY KEY NOT NULL,
  set_id integer NOT NULL,
  user_name varchar(255) NOT NULL,
  purchase_date datetime NOT NULL,
  purchase_value varchar(255) NOT NULL,
  org_name varchar(255) NOT NULL,
  transaction_id integer,
  ignore_value boolean NOT NULL DEFAULT false,
  FOREIGN KEY (set_id) REFERENCES import_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX import_values_idx_set_id ON import_values (set_id);
CREATE INDEX import_values_idx_transaction_id ON import_values (transaction_id);
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
--
-- Table: transaction_category
--
CREATE TABLE transaction_category (
  category_id integer NOT NULL,
  transaction_id integer NOT NULL,
  FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);
CREATE INDEX transaction_category_idx_category_id ON transaction_category (category_id);
CREATE INDEX transaction_category_idx_transaction_id ON transaction_category (transaction_id);
CREATE UNIQUE INDEX transaction_category_transaction_id ON transaction_category (transaction_id);
COMMIT;
