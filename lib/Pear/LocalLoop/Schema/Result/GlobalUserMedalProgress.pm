package Pear::LocalLoop::Schema::Result::GlobalUserMedals;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("global_user_medals");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "entity_id" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "group_id" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "total" => {
    data_type => "integer",
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "entity",
  "Pear::LocalLoop::Schema::Result::Entity",
  "entity_id",
);

__PACKAGE__->belongs_to(
  "group",
  "Pear::LocalLoop::Schema::Result::GlobalMedalGroup",
  { id => "group_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
