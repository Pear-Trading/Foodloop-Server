-- Convert schema 'share/ddl/_source/deploy/20/001-auto.yml' to 'share/ddl/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transaction_category DROP CONSTRAINT transaction_category_fk_category_id;

;
ALTER TABLE transaction_category ADD CONSTRAINT transaction_category_fk_category_id FOREIGN KEY (category_id)
  REFERENCES category (id) ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

