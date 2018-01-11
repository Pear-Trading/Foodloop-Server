-- Convert schema 'share/ddl/_source/deploy/19/001-auto.yml' to 'share/ddl/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE category (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL
);

;
CREATE UNIQUE INDEX category_name ON category (name);

;
CREATE TABLE transaction_category (
  category_id integer NOT NULL,
  transaction_id integer NOT NULL,
  FOREIGN KEY (category_id) REFERENCES category(id),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

;
CREATE INDEX transaction_category_idx_category_id ON transaction_category (category_id);

;
CREATE INDEX transaction_category_idx_transaction_id ON transaction_category (transaction_id);

;
CREATE UNIQUE INDEX transaction_category_transaction_id ON transaction_category (transaction_id);

;

COMMIT;

