package Pear::LocalLoop::Schema::Result::ImportLookup;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("import_lookups");

__PACKAGE__->add_columns(
  id => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  set_id => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  name => {
    data_type => "varchar",
    size => 255,
  },
  entity_id => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "import_set",
  "Pear::LocalLoop::Schema::Result::ImportSet",
  { "foreign.id" => "self.set_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "entity",
  "Pear::LocalLoop::Schema::Result::Entity",
  { "foreign.id" => "self.entity_id" },
  {
    join_type => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

1;
