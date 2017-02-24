use utf8;
package Pear::LocalLoop::Schema::Result::AccountToken;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Pear::LocalLoop::Schema::Result::AccountToken

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

=head1 TABLE: C<AccountTokens>

=cut

__PACKAGE__->table("AccountTokens");

=head1 ACCESSORS

=head2 accounttokenid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 accounttokenname

  data_type: 'text'
  is_nullable: 0

=head2 used

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "accounttokenid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "accounttokenname",
  { data_type => "text", is_nullable => 0 },
  "used",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</accounttokenid>

=back

=cut

__PACKAGE__->set_primary_key("accounttokenid");

=head1 UNIQUE CONSTRAINTS

=head2 C<accounttokenname_unique>

=over 4

=item * L</accounttokenname>

=back

=cut

__PACKAGE__->add_unique_constraint("accounttokenname_unique", ["accounttokenname"]);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-24 17:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MeN6dMZY0drrWk+En7E5Ag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
