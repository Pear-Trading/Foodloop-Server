-- Convert schema 'share/ddl/_source/deploy/9/001-auto.yml' to 'share/ddl/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE customers ADD COLUMN latitude numeric(5,2);

;
ALTER TABLE customers ADD COLUMN longitude numeric(5,2);

;
ALTER TABLE organisations ADD COLUMN latitude numeric(8,5);

;
ALTER TABLE organisations ADD COLUMN longitude numeric(8,5);

;

COMMIT;

