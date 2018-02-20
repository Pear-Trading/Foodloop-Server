package Pear::LocalLoop::Schema::Result::GlobalMedalGroup;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("global_medal_group");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "group_name" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(["group_name"]);

__PACKAGE__->has_many(
  "medals",
  "Pear::LocalLoop::Schema::Result::GlobalMedals",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
