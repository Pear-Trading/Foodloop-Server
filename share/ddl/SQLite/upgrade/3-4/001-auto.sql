-- Convert schema 'share/ddl/_source/deploy/3/001-auto.yml' to 'share/ddl/_source/deploy/4/001-auto.yml':;

;
BEGIN;

CREATE TABLE pending_transactions_old AS SELECT * FROM pending_transactions;

DROP TABLE pending_transactions;

CREATE TABLE pending_transactions (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value decimal(16,2) NOT NULL,
  proof_image text NOT NULL,
  submitted_at datetime NOT NULL,
  purchase_time datetime NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES users(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (seller_id) REFERENCES organisations(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
CREATE INDEX pending_transactions_idx_buyer_id ON pending_transactions (buyer_id);
CREATE INDEX pending_transactions_idx_seller_id ON pending_transactions (seller_id);

INSERT INTO pending_transactions (
  id,
  buyer_id,
  seller_id,
  value,
  proof_image,
  submitted_at,
  purchase_time
) SELECT
    id,
    buyer_id,
    seller_id,
    value,
    proof_image,
    submitted_at,
    submitted_at
  FROM pending_transactions_old;

DROP TABLE pending_transactions_old;
COMMIT;
