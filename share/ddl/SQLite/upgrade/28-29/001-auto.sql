-- Convert schema 'share/ddl/_source/deploy/28/001-auto.yml' to 'share/ddl/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE gb_wards (
  id INTEGER PRIMARY KEY NOT NULL,
  ward varchar(100) NOT NULL
);

;
ALTER TABLE gb_postcodes ADD COLUMN ward_id integer;

;
CREATE INDEX gb_postcodes_idx_ward_id ON gb_postcodes (ward_id);

;

;

COMMIT;

