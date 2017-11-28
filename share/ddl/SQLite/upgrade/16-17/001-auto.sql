-- Convert schema 'share/ddl/_source/deploy/16/001-auto.yml' to 'share/ddl/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE entity_association (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  lis boolean,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE
);

;
CREATE INDEX entity_association_idx_entity_id ON entity_association (entity_id);

;
CREATE TEMPORARY TABLE import_values_temp_alter (
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

;
INSERT INTO import_values_temp_alter( id, set_id, user_name, purchase_date, purchase_value, org_name, transaction_id, ignore_value) SELECT id, set_id, user_name, purchase_date, purchase_value, org_name, transaction_id, ignore_value FROM import_values;

;
DROP TABLE import_values;

;
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

;
CREATE INDEX import_values_idx_set_id02 ON import_values (set_id);

;
CREATE INDEX import_values_idx_transacti00 ON import_values (transaction_id);

;
INSERT INTO import_values SELECT id, set_id, user_name, purchase_date, purchase_value, org_name, transaction_id, ignore_value FROM import_values_temp_alter;

;
DROP TABLE import_values_temp_alter;

;

COMMIT;

