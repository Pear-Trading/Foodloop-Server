package Pear::LocalLoop::Schema::Result::ViewQuantisedTransactionCategoryPg;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('view_quantised_transactions');
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( qq/
SELECT "transactions.value",
       "transactions.distance",
       "transactions.purchase_time",
       "transactions.buyer_id",
       "transactions.seller_id",
       "transactions.essential",
       "transaction_category.category_id",
       DATE_TRUNC('hour', "transactions.purchase_time") AS "quantised_hours",
       DATE_TRUNC('day', "transactions.purchase_time") AS "quantised_days",
       DATE_TRUNC('week', "transactions.purchase_time") AS "quantised_weeks"
  FROM "transactions"
LEFT JOIN "transaction_category" ON "transactions.id" = "transaction_category.transaction_id"
/);

1;
