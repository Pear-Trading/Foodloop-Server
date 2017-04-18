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

sub read {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $user = $c->result_set->find($id) ) {
    $c->stash( user => $user );
  } else {
    $c->flash( error => 'No User found' );
    $c->redirect_to( '/admin/users' );
  }
}

sub update {
  my $c = shift;
  $c->redirect_to( '/admin/users' );
}

1;
