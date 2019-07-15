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
       "buyer_id",
       "seller_id",
       DATE_TRUNC('hour', "purchase_time") AS "quantised_hours",
       DATE_TRUNC('day', "purchase_time") AS "quantised_days",
       DATE_TRUNC('week', "purchase_time") AS "quantised_weeks",
       DATE_TRUNC('month', "purchase_time") AS "quantised_months"
  FROM "transactions"
/);

__PACKAGE__->add_columns(
  "buyer_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "seller_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "value" => {
    data_type => "numeric",
    size => [ 100, 0 ],
    is_nullable => 0,
  },
  "quantised_hours" => {
    data_type => "datetime",
    timezone => "UTC",
    is_nullable => 0,
    set_on_create => 1,
  },
  "quantised_days" => {
    data_type => "datetime",
    timezone => "UTC",
    is_nullable => 0,
    set_on_create => 1,
  },
  "quantised_weeks" => {
    data_type => "datetime",
    timezone => "UTC",
    is_nullable => 0,
    set_on_create => 1,
  },
  "quantised_months" => {
    data_type => "datetime",
    timezone => "UTC",
    is_nullable => 0,
    set_on_create => 1,
  },
);

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
