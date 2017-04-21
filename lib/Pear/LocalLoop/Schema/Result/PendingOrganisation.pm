use utf8;
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

=head1 RELATIONS

=head2 pending_transactions

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::PendingTransaction>

=cut

__PACKAGE__->has_many(
  "pending_transactions",
  "Pear::LocalLoop::Schema::Result::PendingTransaction",
  {
    "foreign.pendingsellerorganisationid_fk" => "self.id",
  },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 usersubmitted_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "submitted_by",
  "Pear::LocalLoop::Schema::Result::User",
  { userid => "submitted_by_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ekEOt+ESCwQxrqqlMurehA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
