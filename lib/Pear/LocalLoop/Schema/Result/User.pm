package Pear::LocalLoop::Schema::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Data::UUID;

__PACKAGE__->load_components( qw/
  InflateColumn::DateTime
  PassphraseColumn
  TimeStamp
/);

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "customer_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "organisation_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "email" => {
    data_type => "text",
    is_nullable => 0,
  },
  "join_date" => {
    data_type => "datetime",
    set_on_create => 1,
  },
  "password" => {
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

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(["customer_id"]);

__PACKAGE__->add_unique_constraint(["email"]);

__PACKAGE__->add_unique_constraint(["organisation_id"]);

__PACKAGE__->might_have(
  "administrator",
  "Pear::LocalLoop::Schema::Result::Administrator",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "customer",
  "Pear::LocalLoop::Schema::Result::Customer",
  { "foreign.id" => "self.customer_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "organisation",
  "Pear::LocalLoop::Schema::Result::Organisation",
  { "foreign.id" => "self.organisation_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "pending_organisations",
  "Pear::LocalLoop::Schema::Result::PendingOrganisation",
  { "foreign.submitted_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "pending_transactions",
  "Pear::LocalLoop::Schema::Result::PendingTransaction",
  { "foreign.buyer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "session_tokens",
  "Pear::LocalLoop::Schema::Result::SessionToken",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "transactions",
  "Pear::LocalLoop::Schema::Result::Transaction",
  { "foreign.buyer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub generate_session {
  my $self = shift;

  my $token = Data::UUID->new->create_str();
  $self->create_related(
    'session_tokens',
    {
      token => $token,
    },
  );

  return $token;
}

1;
