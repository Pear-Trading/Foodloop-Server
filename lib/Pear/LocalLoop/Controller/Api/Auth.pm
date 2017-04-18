package Pear::LocalLoop::Controller::Api::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::JSON;

has error_messages => sub {
  return {
    email => {
      required => { message => 'No email sent.', status => 400 },
      email => { message => 'Email is invalid.', status => 400 },
    },
    password => {
      required => { message => 'No password sent.', status => 400 },
    },
  };
};

sub auth {
  my $c = shift;

  my $session_key = $c->req->json( '/session_key' );

  my $session_result = $c->schema->resultset('SessionToken')->find({ sessiontokenname => $session_key });

  if ( defined $session_result ) {
    $c->stash( api_user => $session_result->user );
    return 1;
  }

  $c->render(
    json => {
      success => Mojo::JSON->false,
      message => 'Invalid Session',
    },
    status => 401,
  );
  return 0;
}

sub post_login {
  my $c = shift;

  my $validation = $c->validation;

  my $json = $c->req->json;

  if ( ! defined $json ){
    return $c->render( json => {
      success => Mojo::JSON->false,
      message => 'No json sent.',
    },
    status => 400); #Malformed request   
  }

  $validation->input( $json );
  $validation->required('email')->email;
  $validation->required('password');

  my $email = $validation->param('email');
  my $password = $validation->param('password');

  if ( $validation->has_error ) {
    my $failed_vals = $validation->failed;
    for my $val ( @$failed_vals ) {
      my $check = shift @{ $validation->error($val) };
      return $c->render(
        json => {
          success => Mojo::JSON->false,
          message => $c->error_messages->{$val}->{$check}->{message},
        },
        status => $c->error_messages->{$val}->{$check}->{status},
      );
    }
  }

  my $user_result = $c->schema->resultset('User')->find({ email => $email });
  
  if ( defined $user_result ) {
    if ( $user_result->check_password($password) ) {
      my $session_key = $c->generate_session( $user_result->userid );

      return $c->render( json => {
        success => Mojo::JSON->true,
        session_key => $session_key,
      });
    }
  } else {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => 'Email or password is invalid.',
      },
      status => 401
    );
  }
}

sub post_logout {
  my $c = shift;

  my $session_key = $c->req->json( '/session_key' );

  my $session_result = $c->schema->resultset('SessionToken')->find({ sessiontokenname => $session_key });

  if ( defined $session_result ) {
    $session_result->delete;
  }

  $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Logged Out',
  }); 
}

1;
