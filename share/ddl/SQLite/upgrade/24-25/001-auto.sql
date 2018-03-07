-- Convert schema 'share/ddl/_source/deploy/24/001-auto.yml' to 'share/ddl/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE transaction_recurring (
  id integer NOT NULL,
  transaction_id integer NOT NULL,
  recurring_period varchar(255) NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

;
CREATE INDEX transaction_recurring_idx_transaction_id ON transaction_recurring (transaction_id);

;
CREATE UNIQUE INDEX transaction_recurring_transaction_id ON transaction_recurring (transaction_id);

;

COMMIT;

