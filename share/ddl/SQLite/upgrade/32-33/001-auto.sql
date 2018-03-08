-- Convert schema 'share/ddl/_source/deploy/32/001-auto.yml' to 'share/ddl/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE transaction_recurring_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value numeric(100,0) NOT NULL,
  start_time datetime NOT NULL,
  last_updated datetime,
  essential boolean NOT NULL DEFAULT false,
  distance numeric(15),
  category_id integer,
  recurring_period varchar(255) NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (category_id) REFERENCES category(id),
  FOREIGN KEY (seller_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
INSERT INTO transaction_recurring_temp_alter( id, buyer_id, seller_id, value, start_time, last_updated, essential, distance, category_id, recurring_period) SELECT id, buyer_id, seller_id, value, start_time, last_updated, essential, distance, category_id, recurring_period FROM transaction_recurring;

;
DROP TABLE transaction_recurring;

;
CREATE TABLE transaction_recurring (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value numeric(100,0) NOT NULL,
  start_time datetime NOT NULL,
  last_updated datetime,
  essential boolean NOT NULL DEFAULT false,
  distance numeric(15),
  category_id integer,
  recurring_period varchar(255) NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (category_id) REFERENCES category(id),
  FOREIGN KEY (seller_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX transaction_recurring_idx_b00 ON transaction_recurring (buyer_id);

;
CREATE INDEX transaction_recurring_idx_c00 ON transaction_recurring (category_id);

;
CREATE INDEX transaction_recurring_idx_s00 ON transaction_recurring (seller_id);

;
INSERT INTO transaction_recurring SELECT id, buyer_id, seller_id, value, start_time, last_updated, essential, distance, category_id, recurring_period FROM transaction_recurring_temp_alter;

;
DROP TABLE transaction_recurring_temp_alter;

;

COMMIT;

