use utf8;
package Pear::LocalLoop::Schema::Result::AgeRange;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::AgeRange

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

=head1 TABLE: C<AgeRanges>

=cut

__PACKAGE__->table("AgeRanges");

=head1 ACCESSORS

=head2 agerangeid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 agerangestring

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "agerangeid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "agerangestring",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</agerangeid>

=back

=cut

__PACKAGE__->set_primary_key("agerangeid");

=head1 UNIQUE CONSTRAINTS

=head2 C<agerangestring_unique>

=over 4

=item * L</agerangestring>

=back

=cut

__PACKAGE__->add_unique_constraint("agerangestring_unique", ["agerangestring"]);

=head1 RELATIONS

=head2 customers

Type: has_many

Related object: L<Pear::LocalLoop::Schema::Result::Customer>

=cut

__PACKAGE__->has_many(
  "customers",
  "Pear::LocalLoop::Schema::Result::Customer",
  { "foreign.agerange_fk" => "self.agerangeid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4zGNm0RlwptF9hlj9oErVA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
