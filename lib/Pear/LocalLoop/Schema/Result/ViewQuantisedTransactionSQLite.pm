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
       "buyer_id",
       "seller_id",
       "sector",
       DATETIME(STRFTIME('%Y-%m-%d %H:00:00',"purchase_time")) AS "quantised_hours",
       DATETIME(STRFTIME('%Y-%m-%d 00:00:00',"purchase_time")) AS "quantised_days",
       DATETIME(STRFTIME('%Y-%m-%d 00:00:00',"purchase_time",'weekday 0','-6 days')) AS "quantised_weeks",
       DATETIME(STRFTIME('%Y-%m-00 00:00:00',"purchase_time")) AS "quantised_months"
  FROM "transactions"
/);

__PACKAGE__->belongs_to(
  "buyer",
  "Pear::LocalLoop::Schema::Result::Entity",
  { id => "buyer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "seller",
  "Pear::LocalLoop::Schema::Result::Entity",
  { id => "seller_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
