package Pear::LocalLoop::Schema::Result::SessionToken;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("session_tokens");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "token" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "user_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(["token"]);

__PACKAGE__->belongs_to(
  "user",
  "Pear::LocalLoop::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
