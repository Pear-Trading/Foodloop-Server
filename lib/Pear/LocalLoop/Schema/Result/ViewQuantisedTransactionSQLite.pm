package Pear::LocalLoop::Schema::Result::ViewQuantisedTransactionSQLite;

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
       DATETIME(STRFTIME('%Y-%m-%d %H:00:00',"purchase_time")) AS "quantised_hours",
       DATETIME(STRFTIME('%Y-%m-%d 00:00:00',"purchase_time")) AS "quantised_days",
       DATETIME(STRFTIME('%Y-%m-%d 00:00:00',"purchase_time", 'weekday 1')) AS "quantised_weeks"
  FROM "transactions"
/);

1;
