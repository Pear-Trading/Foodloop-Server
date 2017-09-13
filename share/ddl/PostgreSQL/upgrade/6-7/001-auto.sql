-- Convert schema 'share/ddl/_source/deploy/6/001-auto.yml' to 'share/ddl/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE leaderboard_values ALTER COLUMN value TYPE numeric(100,0) USING value * 100000;

;
ALTER TABLE transactions ALTER COLUMN value TYPE numeric(100,0) USING value * 100000;

;

COMMIT;

