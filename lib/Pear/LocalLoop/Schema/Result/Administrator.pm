package Pear::LocalLoop::Schema::Result::Administrator;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("Administrators");

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("user_id");

__PACKAGE__->belongs_to(
  "user",
  "Pear::LocalLoop::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
