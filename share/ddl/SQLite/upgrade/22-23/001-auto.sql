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
  group_id integer NOT NULL,
  threshold integer NOT NULL,
  points integer NOT NULL,
  FOREIGN KEY (group_id) REFERENCES global_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX global_medals_idx_group_id ON global_medals (group_id);

;
CREATE TABLE global_user_medal_progress (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
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
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
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
  group_id integer NOT NULL,
  threshold integer NOT NULL,
  points integer NOT NULL,
  FOREIGN KEY (group_id) REFERENCES org_medal_group(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX org_medals_idx_group_id ON org_medals (group_id);

;
CREATE TABLE org_user_medal_progress (
  id INTEGER PRIMARY KEY NOT NULL,
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
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
  entity_id integer NOT NULL,
  group_id integer NOT NULL,
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
CREATE TABLE transaction_recurring (
  id INTEGER PRIMARY KEY NOT NULL,
  buyer_id integer NOT NULL,
  seller_id integer NOT NULL,
  value numeric(100,0) NOT NULL,
  start_time datetime NOT NULL,
  last_updated datetime,
  essential boolean NOT NULL DEFAULT false,
  distance numeric(15),
  category_id integer,
  recurring_period varchar(255) NOT NULL,
  FOREIGN KEY (buyer_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (category_id) REFERENCES category(id),
  FOREIGN KEY (seller_id) REFERENCES entities(id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

;
CREATE INDEX transaction_recurring_idx_buyer_id ON transaction_recurring (buyer_id);

;
CREATE INDEX transaction_recurring_idx_category_id ON transaction_recurring (category_id);

;
CREATE INDEX transaction_recurring_idx_seller_id ON transaction_recurring (seller_id);

;
ALTER TABLE transactions ADD COLUMN essential boolean NOT NULL DEFAULT false;

;

COMMIT;

