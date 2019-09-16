-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Aug 27 17:44:14 2019
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
  name varchar(255) NOT NULL,
  line_icon varchar(255)
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
-- Table: external_references
--
CREATE TABLE external_references (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL
);
CREATE UNIQUE INDEX external_references_name ON external_references (name);
--
-- Table: gb_wards
--
CREATE TABLE gb_wards (
  id INTEGER PRIMARY KEY NOT NULL,
  ward varchar(100) NOT NULL
);
--
-- Table: global_medal_group
--
CREATE TABLE global_medal_group (
  id INTEGER PRIMARY KEY NOT NULL,
  group_name varchar(255) NOT NULL
);
CREATE UNIQUE INDEX global_medal_group_group_name ON global_medal_group (group_name);
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
-- Table: org_medal_group
--
CREATE TABLE org_medal_group (
  id INTEGER PRIMARY KEY NOT NULL,
  group_name varchar(255) NOT NULL
);
CREATE UNIQUE INDEX org_medal_group_group_name ON org_medal_group (group_name);
--
-- Table: organisation_social_types
--
CREATE TABLE organisation_social_types (
  id INTEGER PRIMARY KEY NOT NULL,
  key varchar(255) NOT NULL,
  name varchar(255) NOT NULL
);
CREATE UNIQUE INDEX organisation_social_types_key ON organisation_social_types (key);
--
-- Table: organisation_types
--
CREATE TABLE organisation_types (
  id INTEGER PRIMARY KEY NOT NULL,
  key varchar(255) NOT NULL,
  name varchar(255) NOT NULL
);
CREATE UNIQUE INDEX organisation_types_key ON organisation_types (key);
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
-- Table: gb_postcodes
--
CREATE TABLE gb_postcodes (
  outcode char(4) NOT NULL,
  incode char(3) NOT NULL DEFAULT '',
  latitude decimal(7,5),
  longitude decimal(7,5),
  ward_id integer,
  PRIMARY KEY (outcode, incode),
  FOREIGN KEY (ward_id) REFERENCES gb_wards(id)
);
CREATE INDEX gb_postcodes_idx_ward_id ON gb_postcodes (ward_id);
--
-- Table: global_medals
--
CREATE TABLE global_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  group_id integer NOT NULL,
  threshold integer NOT NULL,
  points integer NOT NULL,
  FOREIGN KEY (group_id) REFERENCES global_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX global_medals_idx_group_id ON global_medals (group_id);
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
-- Table: org_medals
--
CREATE TABLE org_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  group_id integer NOT NULL,
  threshold integer NOT NULL,
  points integer NOT NULL,
  FOREIGN KEY (group_id) REFERENCES org_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX org_medals_idx_group_id ON org_medals (group_id);
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
  essential boolean NOT NULL DEFAULT false,
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
-- Table: global_user_medal_progress
--
CREATE TABLE global_user_medal_progress (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
  total integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES global_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX global_user_medal_progress_idx_entity_id ON global_user_medal_progress (entity_id);
CREATE INDEX global_user_medal_progress_idx_group_id ON global_user_medal_progress (group_id);
--
-- Table: global_user_medals
--
CREATE TABLE global_user_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
  points integer NOT NULL,
  awarded_at datetime NOT NULL,
  threshold integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES global_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX global_user_medals_idx_entity_id ON global_user_medals (entity_id);
CREATE INDEX global_user_medals_idx_group_id ON global_user_medals (group_id);
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
-- Table: org_user_medal_progress
--
CREATE TABLE org_user_medal_progress (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
  total integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES org_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX org_user_medal_progress_idx_entity_id ON org_user_medal_progress (entity_id);
CREATE INDEX org_user_medal_progress_idx_group_id ON org_user_medal_progress (group_id);
--
-- Table: org_user_medals
--
CREATE TABLE org_user_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
  points integer NOT NULL,
  awarded_at datetime NOT NULL,
  threshold integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES org_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX org_user_medals_idx_entity_id ON org_user_medals (entity_id);
CREATE INDEX org_user_medals_idx_group_id ON org_user_medals (group_id);
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
-- Table: transaction_recurring
--
CREATE TABLE transaction_recurring (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value numeric(100,0) NOT NULL,
  start_time datetime NOT NULL,
  last_updated datetime,
  essential boolean NOT NULL DEFAULT false,
  distance numeric(15),
  category_id integer,
  recurring_period varchar(255) NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (category_id) REFERENCES category(id),
  FOREIGN KEY (seller_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX transaction_recurring_idx_buyer_id ON transaction_recurring (buyer_id);
CREATE INDEX transaction_recurring_idx_category_id ON transaction_recurring (category_id);
CREATE INDEX transaction_recurring_idx_seller_id ON transaction_recurring (seller_id);
--
-- Table: transactions_meta
--
CREATE TABLE transactions_meta (
  id INTEGER PRIMARY KEY NOT NULL,
  transaction_id integer NOT NULL,
  net_value numeric(100,0) NOT NULL,
  sales_tax_value numeric(100,0) NOT NULL,
  gross_value numeric(100,0) NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);
CREATE INDEX transactions_meta_idx_transaction_id ON transactions_meta (transaction_id);
--
-- Table: entities_postcodes
--
CREATE TABLE entities_postcodes (
  outcode char(4) NOT NULL,
  incode char(3) NOT NULL,
  entity_id integer NOT NULL,
  PRIMARY KEY (outcode, incode, entity_id),
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE,
  FOREIGN KEY (outcode, incode) REFERENCES gb_postcodes(outcode, incode)
);
CREATE INDEX entities_postcodes_idx_entity_id ON entities_postcodes (entity_id);
CREATE INDEX entities_postcodes_idx_outcode_incode ON entities_postcodes (outcode, incode);
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
  type_id integer,
  social_type_id integer,
  is_anchor boolean NOT NULL DEFAULT FALSE,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE,
  FOREIGN KEY (type_id) REFERENCES organisation_types(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (social_type_id) REFERENCES organisation_social_types(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX organisations_idx_entity_id ON organisations (entity_id);
CREATE INDEX organisations_idx_type_id ON organisations (type_id);
CREATE INDEX organisations_idx_social_type_id ON organisations (social_type_id);
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
--
-- Table: transactions_external
--
CREATE TABLE transactions_external (
  id INTEGER PRIMARY KEY NOT NULL,
  transaction_id integer NOT NULL,
  external_reference_id integer NOT NULL,
  external_id varchar(255) NOT NULL,
  FOREIGN KEY (external_reference_id) REFERENCES external_references(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX transactions_external_idx_external_reference_id ON transactions_external (external_reference_id);
CREATE INDEX transactions_external_idx_transaction_id ON transactions_external (transaction_id);
CREATE UNIQUE INDEX transactions_external_external_reference_id_external_id ON transactions_external (external_reference_id, external_id);
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
-- Table: organisations_external
--
CREATE TABLE organisations_external (
  id INTEGER PRIMARY KEY NOT NULL,
  org_id integer NOT NULL,
  external_reference_id integer NOT NULL,
  external_id varchar(255) NOT NULL,
  FOREIGN KEY (external_reference_id) REFERENCES external_references(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (org_id) REFERENCES organisations(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX organisations_external_idx_external_reference_id ON organisations_external (external_reference_id);
CREATE INDEX organisations_external_idx_org_id ON organisations_external (org_id);
CREATE UNIQUE INDEX organisations_external_external_reference_id_external_id ON organisations_external (external_reference_id, external_id);
COMMIT;
