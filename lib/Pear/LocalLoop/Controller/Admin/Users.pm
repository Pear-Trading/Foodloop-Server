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

sub edit {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $user = $c->result_set->find($id) ) {
    $c->stash( user => $user );
  } else {
    $c->flash( error => 'No User found' );
    $c->redirect_to( '/admin/users/' . $id );
  }

  my $validation = $c->validation;

  $validation->required('email')->not_in_resultset( 'email', $user->id );
  $validation->required('postcode')->postcode;
  $validation->optional('new_password');

  if ( defined $user->customer_id ) {
    $validation->required('display_name');
    $validation->required('full_name');
  } elsif ( defined $user->organisation_id ) {
    $validation->required('name');
    $validation->required('street_name');
    $validation->required('town');
  }

  if ( $validation->has_error ) {
    $c->flash( error => 'The validation has failed' );
    $c->app->log->warn(Dumper $validation);
    return $c->redirect_to( '/admin/users/' . $id );
  }

  if ( defined $user->customer_id ){

    $c->schema->txn_do( sub {
      $user->customer->update({
        full_name     => $validation->param('full_name'),
        display_name  => $validation->param('display_name'),
        postcode      => $validation->param('postcode'),
      });
      $user->update({
        email => $validation->param('email'),
        ( defined $validation->param('new_password') ? ( password => $validation->param('new_password') ) : () ),
      });
    });

  }
  elsif ( defined $user->organisation_id ) {

    $c->schema->txn_do( sub {
      $user->organisation->update({
        name        => $validation->param('name'),
        street_name => $validation->param('street_name'),
        town        => $validation->param('town'),
        postcode    => $validation->param('postcode'),
      });
      $user->update({
        email        => $validation->param('email'),
        ( defined $validation->param('new_password') ? ( password => $validation->param('new_password') ) : () ),
      });
    });
  }

  $c->redirect_to( '/admin/users/' . $id );
}

sub update {
  my $c = shift;
  $c->redirect_to( '/admin/users' );
}

1;
