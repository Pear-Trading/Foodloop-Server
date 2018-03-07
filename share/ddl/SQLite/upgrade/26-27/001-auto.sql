-- Convert schema 'share/ddl/_source/deploy/26/001-auto.yml' to 'share/ddl/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE transaction_recurring_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  transaction_id integer NOT NULL,
  recurring_period varchar(255) NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

;
INSERT INTO transaction_recurring_temp_alter( id, transaction_id, recurring_period) SELECT id, transaction_id, recurring_period FROM transaction_recurring;

;
DROP TABLE transaction_recurring;

;
CREATE TABLE transaction_recurring (
  id INTEGER PRIMARY KEY NOT NULL,
  transaction_id integer NOT NULL,
  recurring_period varchar(255) NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

;
CREATE INDEX transaction_recurring_idx_t00 ON transaction_recurring (transaction_id);

;
CREATE UNIQUE INDEX transaction_recurring_trans00 ON transaction_recurring (transaction_id);

;
INSERT INTO transaction_recurring SELECT id, transaction_id, recurring_period FROM transaction_recurring_temp_alter;

;
DROP TABLE transaction_recurring_temp_alter;

;

COMMIT;

