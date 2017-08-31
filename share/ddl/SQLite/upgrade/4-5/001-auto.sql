-- Convert schema 'share/ddl/_source/deploy/4/001-auto.yml' to 'share/ddl/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE organisations ADD COLUMN sector varchar(1);

;

COMMIT;

