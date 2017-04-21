use utf8;
package Pear::LocalLoop::Schema::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::Customer

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

=head1 TABLE: C<Customers>

=cut

__PACKAGE__->table("Customers");

=head1 ACCESSORS

=head2 customerid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 agerange_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 postcode

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "customerid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "agerange_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "postcode",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</customerid>

=back

=cut

__PACKAGE__->set_primary_key("customerid");

=head1 UNIQUE CONSTRAINTS

=head2 C<username_unique>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

=head1 RELATIONS

=head2 agerange_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::AgeRange>

=cut

__PACKAGE__->belongs_to(
  "agerange_fk",
  "Pear::LocalLoop::Schema::Result::AgeRange",
  { agerangeid => "agerange_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: might_have

Related object: L<Pear::LocalLoop::Schema::Result::User>

=cut

__PACKAGE__->might_have(
  "user",
  "Pear::LocalLoop::Schema::Result::User",
  { "foreign.customer_id" => "self.customerid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ocoCGZYvw9O9wxzr14okiQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
