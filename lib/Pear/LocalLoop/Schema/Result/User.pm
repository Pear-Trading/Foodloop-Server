use utf8;
package Pear::LocalLoop::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 TABLE: C<Users>

=cut

__PACKAGE__->table("Users");

=head1 ACCESSORS

=head2 userid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 customerid_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 organisationalid_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 joindate

  data_type: 'integer'
  is_nullable: 0

=head2 hashedpassword

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "userid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "customerid_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "organisationalid_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "joindate",
  { data_type => "datetime", is_nullable => 0 },
  "hashedpassword",
  {
    data_type => "varchar",
    is_nullable => 0,
    size => 100,
    passphrase => 'crypt',
    passphrase_class => 'BlowfishCrypt',
    passphrase_args => {
      salt_random => 1,
      cost => 8,
    },
    passphrase_check_method => 'check_password',
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</userid>

=back

=cut

__PACKAGE__->set_primary_key("userid");

=head1 UNIQUE CONSTRAINTS

=head2 C<customerid_fk_unique>

=over 4

=item * L</customerid_fk>

=back

=cut

__PACKAGE__->add_unique_constraint("customerid_fk_unique", ["customerid_fk"]);

=head2 C<email_unique>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email_unique", ["email"]);

=head2 C<organisationalid_fk_unique>

=over 4

=item * L</organisationalid_fk>

=back

=cut

__PACKAGE__->add_unique_constraint("organisationalid_fk_unique", ["organisationalid_fk"]);

=head1 RELATIONS

=head2 administrator

Type: might_have

Related object: L<Pear::LocalLoop::Schema::Result::Administrator>

=cut

__PACKAGE__->might_have(
  "administrator",
  "Pear::LocalLoop::Schema::Result::Administrator",
  { "foreign.userid" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 customerid_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "Pear::LocalLoop::Schema::Result::Customer",
  { customerid => "customerid_fk" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 organisationalid_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::Organisation>

=cut

__PACKAGE__->belongs_to(
  "organisation",
  "Pear::LocalLoop::Schema::Result::Organisation",
  { id => "organisationalid_fk" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pending_organisations

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::PendingOrganisation>

=cut

__PACKAGE__->has_many(
  "pending_organisations",
  "Pear::LocalLoop::Schema::Result::PendingOrganisation",
  { "foreign.usersubmitted_fk" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pending_transactions

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::PendingTransaction>

=cut

__PACKAGE__->has_many(
  "pending_transactions",
  "Pear::LocalLoop::Schema::Result::PendingTransaction",
  { "foreign.buyeruserid_fk" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 session_tokens

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::SessionToken>

=cut

__PACKAGE__->has_many(
  "session_tokens",
  "Pear::LocalLoop::Schema::Result::SessionToken",
  { "foreign.useridassignedto_fk" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 transactions

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::Transaction>

=cut

__PACKAGE__->has_many(
  "transactions",
  "Pear::LocalLoop::Schema::Result::Transaction",
  { "foreign.buyeruserid_fk" => "self.userid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qjAgtJR1zaUr00HsiR1aPw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
