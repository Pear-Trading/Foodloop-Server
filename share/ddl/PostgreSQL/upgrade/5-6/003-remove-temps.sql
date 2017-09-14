-- Remove temporary tables created during migration

BEGIN;

DROP INDEX transactions_temp_idx_buyer_id;
DROP INDEX transactions_temp_idx_seller_id;
DROP INDEX session_tokens_temp_idx_user_id;
DROP INDEX feedback_temp_idx_user_id;

DROP TABLE transactions_temp;
DROP TABLE session_tokens_temp;
DROP TABLE feedback_temp;
DROP TABLE pending_transactions;
DROP TABLE administrators;
DROP TABLE pending_organisations;
DROP TABLE users_temp;
DROP TABLE customers_temp;
DROP TABLE organisations_temp;

COMMIT;
