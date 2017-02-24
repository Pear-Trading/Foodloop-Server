use utf8;
package Pear::LocalLoop::Schema::Result::SessionToken;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::SessionToken

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

=head1 TABLE: C<SessionTokens>

=cut

__PACKAGE__->table("SessionTokens");

=head1 ACCESSORS

=head2 sessiontokenid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 sessiontokenname

  data_type: 'text'
  is_nullable: 0

=head2 useridassignedto_fk

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 expiredatetime

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sessiontokenid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "sessiontokenname",
  { data_type => "text", is_nullable => 0 },
  "useridassignedto_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "expiredatetime",
  { data_type => "datetime", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sessiontokenid>

=back

=cut

__PACKAGE__->set_primary_key("sessiontokenid");

=head1 UNIQUE CONSTRAINTS

=head2 C<sessiontokenname_unique>

=over 4

=item * L</sessiontokenname>

=back

=cut

__PACKAGE__->add_unique_constraint("sessiontokenname_unique", ["sessiontokenname"]);

=head1 RELATIONS

=head2 useridassignedto_fk

Type: belongs_to

Related object: L<Pear::LocalLoop::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "useridassignedto_fk",
  "Pear::LocalLoop::Schema::Result::User",
  { userid => "useridassignedto_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/mNAPeSmfsDSIpey+eUucg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
