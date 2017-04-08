package Pear::LocalLoop::Controller::Admin::Tokens;
use Mojo::Base 'Mojolicious::Controller';

has result_set => sub {
  my $c = shift;
  return $c->schema->resultset('AccountToken');
};

sub index {
  my $c = shift;

  my $token_rs = $c->result_set;
  $token_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $c->stash( tokens => [ $token_rs->all ] );
}

# POST
sub create {
  my $c = shift;
  my $validation = $c->validation;
  $validation->required('token-name', 'trim')->like(qr/^[\w]*$/);

  my $token_name = $validation->param('token-name');

  my $token_rs = $c->result_set;
  
  if ( $validation->has_error ) {
    # Only one validator, fairly obvious whats broke
    $c->flash( error => 'Token name not valid - Alphanumeric characters and Underscore only' );
  } elsif ( $token_rs->find({ accounttokenname => $token_name }) ) {
    $c->flash( error => 'Token Already Exists' );
  } else {
    $c->flash( success => 'Token Created' );
    $token_rs->create({ accounttokenname => $token_name });
  }
  $c->redirect_to( '/admin/tokens' );
}

# GET
sub read {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $token = $c->result_set->find($id) ) {
    $c->stash( token => $token );
  } else {
    $c->flash( error => 'No Token found' );
    $c->redirect_to( '/admin/tokens' );
  }
}

# POST
sub update {
  my $c = shift;
  my $validation = $c->validation;
  $validation->required('token-name', 'trim')->like(qr/^[\w]*$/);
  $validation->required('token-used')->in( qw/ 0 1 / );

  my $id = $c->param('id');

  if ( $validation->has_error ) {
    my $names = $validation->failed;
    $c->flash( error => 'Error in submitted data: ' . join(', ', @$names) );
    $c->redirect_to( '/admin/tokens/' . $id );
  } elsif ( my $token = $c->result_set->find($id) ) {
    $token->update({
      accounttokenname => $validation->param('token-name'),
      used => $validation->param('token-used'),
    });
    $c->flash( success => 'Token Updated' );
    $c->redirect_to( '/admin/tokens/' . $id );
  } else {
    $c->flash( error => 'No Token found' );
    $c->redirect_to( '/admin/tokens' );
  }
}

# DELETE
sub delete {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $token = $c->result_set->find($id) ) {
    $token->delete;
    $c->flash( success => 'Token Deleted' );
  } else {
    $c->flash( error => 'No Token found' );
  }
  $c->redirect_to( '/admin/tokens' );
}

1;
