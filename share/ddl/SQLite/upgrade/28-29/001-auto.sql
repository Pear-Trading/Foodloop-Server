-- Convert schema 'share/ddl/_source/deploy/28/001-auto.yml' to 'share/ddl/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transaction_recurring ADD COLUMN category_id integer;

;
CREATE INDEX transaction_recurring_idx_category_id ON transaction_recurring (category_id);

;

;

COMMIT;

