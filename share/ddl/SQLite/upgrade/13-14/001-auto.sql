-- Convert schema 'share/ddl/_source/deploy/13/001-auto.yml' to 'share/ddl/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE import_sets (
  id INTEGER PRIMARY KEY NOT NULL,
  date datetime NOT NULL
);

;
CREATE TABLE import_values (
  id INTEGER PRIMARY KEY NOT NULL,
  set_id integer NOT NULL,
  user_name varchar(255) NOT NULL,
  purchase_date datetime NOT NULL,
  purchase_value varchar(255) NOT NULL,
  org_name varchar(255) NOT NULL,
  transaction_id varchar,
  FOREIGN KEY (set_id) REFERENCES import_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX import_values_idx_set_id ON import_values (set_id);

;
CREATE INDEX import_values_idx_transaction_id ON import_values (transaction_id);

;

COMMIT;

