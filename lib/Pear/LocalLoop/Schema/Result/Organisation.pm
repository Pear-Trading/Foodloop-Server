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
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  "transactions",
  "Pear::LocalLoop::Schema::Result::Transaction",
  { "foreign.seller_id" => 'self.id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
  "user",
  "Pear::LocalLoop::Schema::Result::User",
  { "foreign.organisation_id" => 'self.id' },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
