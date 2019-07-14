-- Convert schema 'share/ddl/_source/deploy/27/001-auto.yml' to 'share/ddl/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE entities_postcodes (
  outcode char(4) NOT NULL,
  incode char(3) NOT NULL,
  entity_id integer NOT NULL,
  PRIMARY KEY (outcode, incode, entity_id),
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE CASCADE,
  FOREIGN KEY (outcode, incode) REFERENCES gb_postcodes(outcode, incode)
);

;
CREATE INDEX entities_postcodes_idx_entity_id ON entities_postcodes (entity_id);

;
CREATE INDEX entities_postcodes_idx_outcode_incode ON entities_postcodes (outcode, incode);

;

COMMIT;

