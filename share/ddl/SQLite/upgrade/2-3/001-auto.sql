-- Convert schema 'share/ddl/_source/deploy/2/001-auto.yml' to 'share/ddl/_source/deploy/3/001-auto.yml':;

;
BEGIN;

CREATE TABLE transactions_old AS SELECT * FROM transactions;

DROP TABLE transactions;

CREATE TABLE transactions (
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
CREATE INDEX transactions_idx_buyer_id ON transactions (buyer_id);
CREATE INDEX transactions_idx_seller_id ON transactions (seller_id);

INSERT INTO transactions (
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
  FROM transactions_old;

DROP TABLE transactions_old;

COMMIT;
