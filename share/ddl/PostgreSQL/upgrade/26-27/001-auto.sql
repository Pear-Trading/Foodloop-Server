-- Convert schema 'share/ddl/_source/deploy/26/001-auto.yml' to 'share/ddl/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transaction_recurring ALTER COLUMN recurring_period SET NOT NULL;

;
ALTER TABLE transaction_recurring ADD PRIMARY KEY (id);

;

COMMIT;

