package Pear::LocalLoop::Schema::Result::TransactionRecurring;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("transaction_recurring");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "transaction_id" => {
    data_type => 'integer',
    is_nullable => 0,
    is_foreign_key => 1,
  },
  "recurring_period" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
);

__PACKAGE__->add_unique_constraint(["transaction_id"]);

__PACKAGE__->belongs_to(
  "transaction",
  "Pear::LocalLoop::Schema::Result::Transaction",
  "transaction_id",
  { cascade_delete => 0 },
);

1;
