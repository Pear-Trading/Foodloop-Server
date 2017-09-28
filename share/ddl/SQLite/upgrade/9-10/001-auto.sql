-- Convert schema 'share/ddl/_source/deploy/9/001-auto.yml' to 'share/ddl/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE customers ADD COLUMN latitude decimal(5,2);

;
ALTER TABLE customers ADD COLUMN longitude decimal(5,2);

;
ALTER TABLE organisations ADD COLUMN latitude decimal(8,5);

;
ALTER TABLE organisations ADD COLUMN longitude decimal(8,5);

;

COMMIT;

