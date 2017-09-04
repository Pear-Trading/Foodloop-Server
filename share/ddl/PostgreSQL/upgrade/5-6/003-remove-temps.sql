-- Remove temporary tables created during migration

BEGIN;

DROP TABLE customers_temp;
DROP TABLE organisations_temp;
DROP TABLE transactions_temp;
DROP TABLE users_temp;
DROP TABLE pending_organisations;
DROP TABLE pending_transactions;
DROP TABLE administrators;

COMMIT;
