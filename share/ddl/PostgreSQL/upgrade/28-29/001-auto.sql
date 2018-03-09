-- Convert schema 'share/ddl/_source/deploy/28/001-auto.yml' to 'share/ddl/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transaction_recurring ADD COLUMN category_id integer;

;
CREATE INDEX transaction_recurring_idx_category_id on transaction_recurring (category_id);

;
ALTER TABLE transaction_recurring ADD CONSTRAINT transaction_recurring_fk_category_id FOREIGN KEY (category_id)
  REFERENCES category (id) DEFERRABLE;

;

COMMIT;

