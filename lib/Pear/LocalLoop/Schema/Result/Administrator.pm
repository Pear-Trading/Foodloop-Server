use utf8;
package Pear::LocalLoop::Schema::Result::Administrator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::Administrator

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

=head1 TABLE: C<Administrators>

=cut

__PACKAGE__->table("Administrators");

=head1 ACCESSORS

=head2 userid

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "userid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</userid>

=back

=cut

__PACKAGE__->set_primary_key("userid");

=head1 RELATIONS

=head2 userid

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "userid",
  "Pear::LocalLoop::Schema::Result::User",
  { userid => "userid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YLzlp1ru+1id/O4bTJGqbw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
