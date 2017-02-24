use utf8;
package Pear::LocalLoop::Schema::Result::Organisation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::Organisation

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

=head1 TABLE: C<Organisations>

=cut

__PACKAGE__->table("Organisations");

=head1 ACCESSORS

=head2 organisationalid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 fulladdress

  data_type: 'text'
  is_nullable: 0

=head2 postcode

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "organisationalid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "fulladdress",
  { data_type => "text", is_nullable => 0 },
  "postcode",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</organisationalid>

=back

=cut

__PACKAGE__->set_primary_key("organisationalid");

=head1 RELATIONS

=head2 transactions

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::Transaction>

=cut

__PACKAGE__->has_many(
  "transactions",
  "Pear::LocalLoop::Schema::Result::Transaction",
  { "foreign.sellerorganisationid_fk" => "self.organisationalid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: might_have

Related object: L<Pear::LocalLoop::Schema::Result::User>

=cut

__PACKAGE__->might_have(
  "user",
  "Pear::LocalLoop::Schema::Result::User",
  { "foreign.organisationalid_fk" => "self.organisationalid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:p9FzM/H5YQbo2d0lN/DfCg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
