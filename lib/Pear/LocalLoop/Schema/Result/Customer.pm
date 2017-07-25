package Pear::LocalLoop::Schema::Result::Customer;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("customers");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "display_name" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "full_name" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "year_of_birth" => {
    data_type => "integer",
    is_nullable => 0,
  },
  "postcode" => {
    data_type => "varchar",
    size => 16,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->might_have(
  "user",
  "Pear::LocalLoop::Schema::Result::User",
  { "foreign.customer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
