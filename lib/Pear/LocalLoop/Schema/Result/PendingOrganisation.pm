use utf8;
package Pear::LocalLoop::Schema::Result::PendingOrganisation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::PendingOrganisation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<PendingOrganisations>

=cut

__PACKAGE__->table("PendingOrganisations");

=head1 ACCESSORS

=head2 pendingorganisationid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 usersubmitted_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 timedatesubmitted

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 fulladdress

  data_type: 'text'
  is_nullable: 1

=head2 postcode

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pendingorganisationid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "usersubmitted_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "timedatesubmitted",
  { data_type => "datetime", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "fulladdress",
  { data_type => "text", is_nullable => 1 },
  "postcode",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pendingorganisationid>

=back

=cut

__PACKAGE__->set_primary_key("pendingorganisationid");

=head1 RELATIONS

=head2 pending_transactions

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::PendingTransaction>

=cut

__PACKAGE__->has_many(
  "pending_transactions",
  "Pear::LocalLoop::Schema::Result::PendingTransaction",
  {
    "foreign.pendingsellerorganisationid_fk" => "self.pendingorganisationid",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 usersubmitted_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "usersubmitted_fk",
  "Pear::LocalLoop::Schema::Result::User",
  { userid => "usersubmitted_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ekEOt+ESCwQxrqqlMurehA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
