package Pear::LocalLoop::Schema::Result::TransactionMeta;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("transactions_meta");

__PACKAGE__->add_columns(
    "id"              => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "transaction_id"  => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "net_value"       => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "sales_tax_value" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "gross_value"     => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "local_service" => {
      data_type => 'boolean',
      default_value => \"false",
      is_nullable => 0,
    },
    "regional_service" => {
      data_type => 'boolean',
      default_value => \"false",
      is_nullable => 0,
    },
    "national_service" => {
      data_type   => 'boolean',
      default_value => \"false",
      is_nullable => 0,
    },
    "private_household_rebate" => {
      data_type   => 'boolean',
      default_value => \"false",
      is_nullable => 0,
    },
    "business_tax_and_rebate" => {
      data_type   => 'boolean',
      default_value => \"false",
      is_nullable => 0,
    },
    "stat_loc_gov" => {
      data_type   => 'boolean',
      default_value => \"false",
      is_nullable => 0,
    },
    "central_loc_gov" => {
      data_type   => 'boolean',
      default_value => \"false",
      is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "transaction",
    "Pear::LocalLoop::Schema::Result::Transaction",
    { 'foreign.id' => 'self.transaction_id' },
);

1;
