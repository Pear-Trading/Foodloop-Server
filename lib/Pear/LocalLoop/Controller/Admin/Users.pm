package Pear::LocalLoop::Controller::Admin::Users;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;
use Data::Dumper;

has user_result_set => sub {
  my $c = shift;
  return $c->schema->resultset('User');
};

has customer_result_set => sub {
  my $c = shift;
  return $c->schema->resultset('Customer');
};

has organisation_result_set => sub {
  my $c = shift;
  return $c->schema->resultset('Organisation');
};

sub index {
  my $c = shift;

  my $user_rs = $c->user_result_set;
  $user_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $c->stash( users => [ $user_rs->all ] );
}

sub read {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $user = $c->user_result_set->find($id) ) {
    $c->stash( user => $user );
  } else {
    $c->flash( error => 'No User found' );
    $c->redirect_to( '/admin/users' );
  }
}

sub update {
  my $c = shift;

  my $id = $c->param('id');

  my $user;

  unless ( $user = $c->user_result_set->find($id) ) {
    $c->flash( error => 'No User found' );
    return $c->redirect_to( '/admin/users/' . $id );
  }

  my $validation = $c->validation;

  my $not_myself_user_rs = $c->user_result_set->search({
    id => { "!=" => $user->id },
  });
  $validation->required('email')->email->not_in_resultset( 'email', $not_myself_user_rs );
  $validation->required('postcode')->postcode;
  $validation->optional('new_password');

  if ( $user->type eq 'customer' ) {
    $validation->required('display_name');
    $validation->required('full_name');
  } elsif ( $user->type eq 'organisation' ) {
    $validation->required('name');
    $validation->required('street_name');
    $validation->required('town');
    $validation->optional('sector');
  }

  if ( $validation->has_error ) {
    $c->flash( error => 'The validation has failed' );
    return $c->redirect_to( '/admin/users/' . $id );
  }

  if ( $user->type eq 'customer' ){

    try {
      $c->schema->txn_do( sub {
        $user->entity->customer->update({
          full_name     => $validation->param('full_name'),
          display_name  => $validation->param('display_name'),
          postcode      => $validation->param('postcode'),
        });
        $user->update({
          email => $validation->param('email'),
          ( defined $validation->param('new_password') ? ( password => $validation->param('new_password') ) : () ),
        });
      });
    } finally {
      if ( @_ ) {
        $c->flash( error => 'Something went wrong Updating the User' );
        $c->app->log->warn(Dumper @_);
      } else {
        $c->flash( success => 'Updated User' );
      };
    }
  }
  elsif ( $user->type eq 'organisation' ) {

    try {
      $c->schema->txn_do( sub {
        $user->entity->organisation->update({
          name        => $validation->param('name'),
          street_name => $validation->param('street_name'),
          town        => $validation->param('town'),
          sector      => $validation->param('sector'),
          postcode    => $validation->param('postcode'),
        });
        $user->update({
          email        => $validation->param('email'),
          ( defined $validation->param('new_password') ? ( password => $validation->param('new_password') ) : () ),
        });
      });
    } finally {
      if ( @_ ) {
        $c->flash( error => 'Something went wrong Updating the User' );
        $c->app->log->warn(Dumper @_);
      } else {
        $c->flash( success => 'Updated User' );
      }
    }
  };

  $c->redirect_to( '/admin/users/' . $id );
}

1;
