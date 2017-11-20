-- Convert schema 'share/ddl/_source/deploy/15/001-auto.yml' to 'share/ddl/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE import_lookups (
  id INTEGER PRIMARY KEY NOT NULL,
  set_id integer NOT NULL,
  name varchar(255) NOT NULL,
  entity_id integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (set_id) REFERENCES import_sets(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX import_lookups_idx_entity_id ON import_lookups (entity_id);

;
CREATE INDEX import_lookups_idx_set_id ON import_lookups (set_id);

;

COMMIT;

