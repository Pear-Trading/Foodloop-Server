use utf8;
package Pear::LocalLoop::Schema::Result::PendingTransaction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::PendingTransaction

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

=head1 TABLE: C<PendingTransactions>

=cut

__PACKAGE__->table("PendingTransactions");

=head1 ACCESSORS

=head2 pendingtransactionid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 buyeruserid_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pendingsellerorganisationid_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 valuemicrocurrency

  data_type: 'integer'
  is_nullable: 0

=head2 proofimage

  data_type: 'text'
  is_nullable: 0

=head2 timedatesubmitted

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pendingtransactionid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "buyeruserid_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pendingsellerorganisationid_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "valuemicrocurrency",
  { data_type => "integer", is_nullable => 0 },
  "proofimage",
  { data_type => "text", is_nullable => 0 },
  "timedatesubmitted",
  { data_type => "datetime", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pendingtransactionid>

=back

=cut

__PACKAGE__->set_primary_key("pendingtransactionid");

=head1 UNIQUE CONSTRAINTS

=head2 C<proofimage_unique>

=over 4

=item * L</proofimage>

=back

=cut

__PACKAGE__->add_unique_constraint("proofimage_unique", ["proofimage"]);

=head1 RELATIONS

=head2 buyeruserid_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "buyeruserid_fk",
  "Pear::LocalLoop::Schema::Result::User",
  { userid => "buyeruserid_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 pendingsellerorganisationid_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::PendingOrganisation>

=cut

__PACKAGE__->belongs_to(
  "pendingsellerorganisationid_fk",
  "Pear::LocalLoop::Schema::Result::PendingOrganisation",
  { pendingorganisationid => "pendingsellerorganisationid_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zwtxzfW5uB4FNA6mKdFOvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
