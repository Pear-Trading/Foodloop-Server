-- Convert schema 'share/ddl/_source/deploy/24/001-auto.yml' to 'share/ddl/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE transactions_meta (
  id INTEGER PRIMARY KEY NOT NULL,
  transaction_id integer NOT NULL,
  net_value numeric(100,0) NOT NULL,
  sales_tax_value numeric(100,0) NOT NULL,
  gross_value numeric(100,0) NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

;
CREATE INDEX transactions_meta_idx_transaction_id ON transactions_meta (transaction_id);

;

COMMIT;

