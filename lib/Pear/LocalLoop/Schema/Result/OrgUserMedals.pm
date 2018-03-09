package Pear::LocalLoop::Schema::Result::OrgUserMedals;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/
  InflateColumn::DateTime
  TimeStamp
/);

__PACKAGE__->table("org_user_medals");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "entity_id" => {
    data_type => "integer",
    is_nullable => 0,
  },
  "group_id" => {
    data_type => "integer",
    is_nullable => 0,
  },
  "points" => {
    data_type => "integer",
    is_nullable => 0,
  },
  "awarded_at" => {
    data_type => "datetime",
    is_nullable => 0,
    set_on_create => 1,
  },
  "threshold" => {
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
  "Pear::LocalLoop::Schema::Result::OrgMedalGroup",
  { id => "group_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
