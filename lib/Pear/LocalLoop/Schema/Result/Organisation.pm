package Pear::LocalLoop::Schema::Result::Organisation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("organisations");

__PACKAGE__->add_columns(
  id => {
    data_type => 'integer',
    is_auto_increment => 1,
    is_nullable => 0,
  },
  entity_id => {
    data_type => 'integer',
    is_nullable => 0,
    is_foreign_key => 1,
  },
  name => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 0,
  },
  street_name => {
    data_type => 'text',
    is_nullable => 1,
  },
  town => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 0,
  },
  postcode => {
    data_type => 'varchar',
    size => 16,
    is_nullable => 1,
  },
  country => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 1,
  },
  sector => {
    data_type => 'varchar',
    size => 1,
    is_nullable => 1,
  },
  pending => {
    data_type => 'boolean',
    default_value => \"0",
    is_nullable => 0,
  },
  submitted_by_id => {
    data_type => 'integer',
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  "entity",
  "Pear::LocalLoop::Schema::Result::Entity",
  "entity_id",
);

1;
