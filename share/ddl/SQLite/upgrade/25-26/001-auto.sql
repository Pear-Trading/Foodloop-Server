-- Convert schema 'share/ddl/_source/deploy/25/001-auto.yml' to 'share/ddl/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE external_references (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL
);

;
CREATE UNIQUE INDEX external_references_name ON external_references (name);

;
CREATE TABLE organisation_social_types (
  id INTEGER PRIMARY KEY NOT NULL,
  key varchar(255) NOT NULL,
  name varchar(255) NOT NULL
);

;
CREATE UNIQUE INDEX organisation_social_types_key ON organisation_social_types (key);

;
CREATE TABLE organisation_types (
  id INTEGER PRIMARY KEY NOT NULL,
  key varchar(255) NOT NULL,
  name varchar(255) NOT NULL
);

;
CREATE UNIQUE INDEX organisation_types_key ON organisation_types (key);

;
CREATE TABLE organisations_external (
  id INTEGER PRIMARY KEY NOT NULL,
  org_id integer NOT NULL,
  external_reference_id integer NOT NULL,
  external_id varchar(255) NOT NULL,
  FOREIGN KEY (external_reference_id) REFERENCES external_references(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (org_id) REFERENCES organisations(id)
);

;
CREATE INDEX organisations_external_idx_external_reference_id ON organisations_external (external_reference_id);

;
CREATE INDEX organisations_external_idx_org_id ON organisations_external (org_id);

;
CREATE UNIQUE INDEX organisations_external_external_reference_id_external_id ON organisations_external (external_reference_id, external_id);

;
CREATE TABLE transactions_external (
  id INTEGER PRIMARY KEY NOT NULL,
  transaction_id integer NOT NULL,
  external_reference_id integer NOT NULL,
  external_id varchar(255) NOT NULL,
  FOREIGN KEY (external_reference_id) REFERENCES external_references(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX transactions_external_idx_external_reference_id ON transactions_external (external_reference_id);

;
CREATE INDEX transactions_external_idx_transaction_id ON transactions_external (transaction_id);

;
CREATE UNIQUE INDEX transactions_external_external_reference_id_external_id ON transactions_external (external_reference_id, external_id);

;
ALTER TABLE organisations ADD COLUMN type_id integer;

;
ALTER TABLE organisations ADD COLUMN social_type_id integer;

;
ALTER TABLE organisations ADD COLUMN is_anchor boolean NOT NULL DEFAULT FALSE;

;
CREATE INDEX organisations_idx_type_id ON organisations (type_id);

;
CREATE INDEX organisations_idx_social_type_id ON organisations (social_type_id);

;

;

;

COMMIT;

