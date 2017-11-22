package Pear::LocalLoop::Schema::Result::ImportValue;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( qw/
  InflateColumn::DateTime
/);

__PACKAGE__->table("import_values");

__PACKAGE__->add_columns(
  id => {
    data_type => 'integer',
    is_auto_increment => 1,
    is_nullable => 0,
  },
  set_id => {
    data_type => 'integer',
    is_foreign_key => 1,
    is_nullable => 0,
  },
  user_name => {
    data_type => 'varchar',
    size => 255,
  },
  purchase_date => {
    data_type => "datetime",
    is_nullable => 0,
  },
  purchase_value => {
    data_type => 'varchar',
    size => 255,
  },
  org_name => {
    data_type => 'varchar',
    size => 255,
  },
  transaction_id => {
    data_type => 'integer',
    is_foreign_key => 1,
    is_nullable => 1,
  },
  ignore_value => {
    data_type => 'boolean',
    default_value => \'false',
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
  "transaction",
  "Pear::LocalLoop::Schema::Result::Transaction",
  { "foreign.id" => "self.transaction_id" },
  {
    join_type => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

1;
