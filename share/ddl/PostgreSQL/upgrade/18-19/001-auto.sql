-- Convert schema 'share\ddl\_source\deploy\18\001-auto.yml' to 'share\ddl\_source\deploy\19\001-auto.yml':;

;
BEGIN;

;
ALTER TABLE organisations ADD COLUMN is_fair boolean;

;

COMMIT;

