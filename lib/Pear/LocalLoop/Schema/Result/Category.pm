package Pear::LocalLoop::Schema::Result::Category;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("category");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  # See here for all possible options http://simplelineicons.com/
  "line_icon" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(["name"]);

__PACKAGE__->has_many(
  "transaction_category",
  "Pear::LocalLoop::Schema::Result::TransactionCategory",
  { "foreign.category_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

__PACKAGE__->many_to_many(
  "transactions",
  "transaction_category",
  "transaction",
);

1;
