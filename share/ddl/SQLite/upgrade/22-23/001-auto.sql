-- Convert schema 'share/ddl/_source/deploy/22/001-auto.yml' to 'share/ddl/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE global_medal_group (
  id INTEGER PRIMARY KEY NOT NULL,
  group_name varchar(255) NOT NULL
);

;
CREATE UNIQUE INDEX global_medal_group_group_name ON global_medal_group (group_name);

;
CREATE TABLE global_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  group_id varchar(255) NOT NULL,
  threshold integer NOT NULL,
  points integer NOT NULL,
  FOREIGN KEY (group_id) REFERENCES global_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX global_medals_idx_group_id ON global_medals (group_id);

;
CREATE TABLE global_user_medal_progress (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id varchar(255) NOT NULL,
  group_id varchar(255) NOT NULL,
  total integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES global_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX global_user_medal_progress_idx_entity_id ON global_user_medal_progress (entity_id);

;
CREATE INDEX global_user_medal_progress_idx_group_id ON global_user_medal_progress (group_id);

;
CREATE TABLE global_user_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id varchar(255) NOT NULL,
  group_id varchar(255) NOT NULL,
  points integer NOT NULL,
  awarded_at datetime NOT NULL,
  threshold integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES global_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX global_user_medals_idx_entity_id ON global_user_medals (entity_id);

;
CREATE INDEX global_user_medals_idx_group_id ON global_user_medals (group_id);

;
CREATE TABLE org_medal_group (
  id INTEGER PRIMARY KEY NOT NULL,
  group_name varchar(255) NOT NULL
);

;
CREATE UNIQUE INDEX org_medal_group_group_name ON org_medal_group (group_name);

;
CREATE TABLE org_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  group_id varchar(255) NOT NULL,
  threshold integer NOT NULL,
  points integer NOT NULL,
  FOREIGN KEY (group_id) REFERENCES org_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX org_medals_idx_group_id ON org_medals (group_id);

;
CREATE TABLE org_user_medal_progress (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id varchar(255) NOT NULL,
  group_id varchar(255) NOT NULL,
  total integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES org_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX org_user_medal_progress_idx_entity_id ON org_user_medal_progress (entity_id);

;
CREATE INDEX org_user_medal_progress_idx_group_id ON org_user_medal_progress (group_id);

;
CREATE TABLE org_user_medals (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id varchar(255) NOT NULL,
  group_id varchar(255) NOT NULL,
  points integer NOT NULL,
  awarded_at datetime NOT NULL,
  threshold integer NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(id),
  FOREIGN KEY (group_id) REFERENCES org_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX org_user_medals_idx_entity_id ON org_user_medals (entity_id);

;
CREATE INDEX org_user_medals_idx_group_id ON org_user_medals (group_id);

;

COMMIT;

