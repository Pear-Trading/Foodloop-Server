-- Convert schema 'share/ddl/_source/deploy/8/001-auto.yml' to 'share/ddl/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "gb_postcodes" (
  "outcode" character(4) NOT NULL,
  "incode" character(3) DEFAULT '' NOT NULL,
  "latitude" numeric(7,5),
  "longitude" numeric(7,5),
  PRIMARY KEY ("outcode", "incode")
);

;

COMMIT;

