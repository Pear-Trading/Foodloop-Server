package Pear::LocalLoop::Schema::Result::ViewQuantisedTransactionPg;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('view_quantised_transactions');
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition( qq/
SELECT "value",
       "distance",
       "purchase_time",
       DATE_TRUNC('hour', "purchase_time") AS "quantised_hours",
       DATE_TRUNC('day', "purchase_time") AS "quantised_days",
       DATE_TRUNC('week', "purchase_time") AS "quantised_weeks"
  FROM "transactions"
/);

1;
