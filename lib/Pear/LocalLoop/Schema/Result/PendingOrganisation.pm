package Pear::LocalLoop::Schema::Result::PendingOrganisation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("pending_organisations");

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
  submitted_by_id => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  submitted_at => {
    data_type => "datetime",
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  "pending_transactions",
  "Pear::LocalLoop::Schema::Result::PendingTransaction",
  {
    "foreign.pendingsellerorganisationid_fk" => "self.id",
  },
  { cascade_copy => 0, cascade_delete => 1 },
);

__PACKAGE__->belongs_to(
  "submitted_by",
  "Pear::LocalLoop::Schema::Result::User",
  { id => "submitted_by_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
