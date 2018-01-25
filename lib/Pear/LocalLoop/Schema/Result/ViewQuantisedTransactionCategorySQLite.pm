package Pear::LocalLoop::Schema::Result::ViewQuantisedTransactionCategorySQLite;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('view_quantised_transactions');
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( qq/
SELECT "transactions"."value",
       "transactions"."distance",
       "transactions"."purchase_time",
       "transactions"."buyer_id",
       "transactions"."seller_id",
       "transaction_category"."category_id",
       DATETIME(STRFTIME('%Y-%m-%d %H:00:00',"transactions"."purchase_time")) AS "quantised_hours",
       DATETIME(STRFTIME('%Y-%m-%d 00:00:00',"transactions"."purchase_time")) AS "quantised_days",
       DATETIME(STRFTIME('%Y-%m-%d 00:00:00',"transactions"."purchase_time", 'weekday 1')) AS "quantised_weeks"
  FROM "transactions"
LEFT JOIN "transaction_category" ON "transactions"."id" = "transaction_category"."transaction_id"
/);

1;
