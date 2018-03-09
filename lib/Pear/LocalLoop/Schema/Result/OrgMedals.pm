package Pear::LocalLoop::Schema::Result::OrgMedals;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("org_medals");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "group_id" => {
    data_type => "integer",
    is_nullable => 0,
  },
  "threshold" => {
    data_type => "integer",
    is_nullable => 0,
  },
  "points" => {
    data_type => "integer",
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "group",
  "Pear::LocalLoop::Schema::Result::OrgMedalGroup",
  { id => "group_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
