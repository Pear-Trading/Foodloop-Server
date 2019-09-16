-- Convert schema 'share/ddl/_source/deploy/29/001-auto.yml' to 'share/ddl/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE transactions_meta ADD COLUMN local_service boolean NOT NULL DEFAULT false;

;
ALTER TABLE transactions_meta ADD COLUMN regional_service boolean NOT NULL DEFAULT false;

;
ALTER TABLE transactions_meta ADD COLUMN national_service boolean NOT NULL DEFAULT false;

;
ALTER TABLE transactions_meta ADD COLUMN private_household_rebate boolean NOT NULL DEFAULT false;

;
ALTER TABLE transactions_meta ADD COLUMN business_tax_and_rebate boolean NOT NULL DEFAULT false;

;
ALTER TABLE transactions_meta ADD COLUMN stat_loc_gov boolean NOT NULL DEFAULT false;

;
ALTER TABLE transactions_meta ADD COLUMN central_loc_gov boolean NOT NULL DEFAULT false;

;

COMMIT;

