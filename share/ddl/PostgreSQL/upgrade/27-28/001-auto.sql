-- Convert schema 'share/ddl/_source/deploy/27/001-auto.yml' to 'share/ddl/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transaction_recurring DROP CONSTRAINT transaction_recurring_transaction_id;

;
ALTER TABLE transaction_recurring DROP CONSTRAINT transaction_recurring_fk_transaction_id;

;
DROP INDEX transaction_recurring_idx_transaction_id;

;
ALTER TABLE transaction_recurring DROP COLUMN transaction_id;

;
ALTER TABLE transaction_recurring ADD COLUMN buyer_id integer NOT NULL;

;
ALTER TABLE transaction_recurring ADD COLUMN seller_id integer NOT NULL;

;
ALTER TABLE transaction_recurring ADD COLUMN value numeric(100,0) NOT NULL;

;
ALTER TABLE transaction_recurring ADD COLUMN start_time timestamp NOT NULL;

;
ALTER TABLE transaction_recurring ADD COLUMN last_updated timestamp NOT NULL;

;
ALTER TABLE transaction_recurring ADD COLUMN essential boolean DEFAULT false NOT NULL;

;
CREATE INDEX transaction_recurring_idx_buyer_id on transaction_recurring (buyer_id);

;
CREATE INDEX transaction_recurring_idx_seller_id on transaction_recurring (seller_id);

;
ALTER TABLE transaction_recurring ADD CONSTRAINT transaction_recurring_fk_buyer_id FOREIGN KEY (buyer_id)
  REFERENCES entities (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE transaction_recurring ADD CONSTRAINT transaction_recurring_fk_seller_id FOREIGN KEY (seller_id)
  REFERENCES entities (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

