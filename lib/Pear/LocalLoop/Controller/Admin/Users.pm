package Pear::LocalLoop::Controller::Admin::Users;
use Mojo::Base 'Mojolicious::Controller';

has result_set => sub {
  my $c = shift;
  return $c->schema->resultset('User');
};

sub index {
  my $c = shift;

  my $user_rs = $c->result_set;
  $user_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $c->stash( users => [ $user_rs->all ] );
}

sub create {
  my $c = shift;
}

sub read {
  my $c = shift;
}

sub update {
  my $c = shift;
}

sub delete {
  my $c = shift;
}

1;
