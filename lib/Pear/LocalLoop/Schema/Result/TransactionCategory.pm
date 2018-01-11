package Pear::LocalLoop::Schema::Result::TransactionCategory;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("transaction_category");

__PACKAGE__->add_columns(
  "category_id" => {
    data_type => "integer",
    is_nullable => 0,
    is_foreign_key => 1,
  },
  "transaction_id" => {
    data_type => 'integer',
    is_nullable => 0,
    is_foreign_key => 1,
  },
);

__PACKAGE__->add_unique_constraint(["transaction_id"]);

__PACKAGE__->belongs_to(
  "category",
  "Pear::LocalLoop::Schema::Result::Category",
  "category_id",
);

__PACKAGE__->belongs_to(
  "transaction",
  "Pear::LocalLoop::Schema::Result::Transaction",
  "transaction_id",
);
