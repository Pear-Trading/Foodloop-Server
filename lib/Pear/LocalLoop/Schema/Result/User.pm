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
  "entity_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
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
  "is_admin" => {
    data_type => "boolean",
    default_value => \"0",
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(["email"]);

__PACKAGE__->belongs_to(
  "entity",
  "Pear::LocalLoop::Schema::Result::Entity",
  "entity_id",
);

__PACKAGE__->has_many(
  "session_tokens",
  "Pear::LocalLoop::Schema::Result::SessionToken",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "feedback",
  "Pear::LocalLoop::Schema::Result::Feedback",
  { "foreign.user_id" => "self.id" },
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

sub name {
  my $self = shift;

  if ( defined $self->entity->customer ) {
    return $self->entity->customer->display_name;
  } elsif ( defined $self->entity->organisation ) {
    return $self->entity->organisation->name;
  } else {
    return;
  }
}

# TODO Deprecate this sub?
sub type {
  my $self = shift;

  return $self->entity->type;
}

1;
