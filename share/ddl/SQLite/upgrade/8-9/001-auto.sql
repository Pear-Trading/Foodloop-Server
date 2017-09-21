-- Convert schema 'share/ddl/_source/deploy/8/001-auto.yml' to 'share/ddl/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE gb_postcodes (
  outcode char(4) NOT NULL,
  incode char(3) NOT NULL DEFAULT '',
  latitude decimal(7,5),
  longitude decimal(7,5),
  PRIMARY KEY (outcode, incode)
);

;

COMMIT;

