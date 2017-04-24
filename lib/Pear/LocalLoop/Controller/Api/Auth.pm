package Pear::LocalLoop::Controller::Api::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::JSON qw/ decode_json /;

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

sub check_json {
  my $c = shift;

  # JSON object is either the whole request, or under a json param for upload
  my $json = $c->req->json || decode_json( $c->param('json') || '{}' );

  unless ( defined $json && ref $json eq 'HASH' && scalar( keys %$json ) > 0 ) {
    $c->render(
      json => {
        success => Mojo::JSON->false,
        message => 'JSON is missing.',
      },
      status => 400,
    );
    return 0;
  }

  $c->stash( api_json => $json );
  return 1;
}

sub auth {
  my $c = shift;

  my $session_key = $c->stash->{api_json}->{session_key};

  if ( defined $session_key ) {
    my $session_result = $c->schema->resultset('SessionToken')->find({ token => $session_key });

    if ( defined $session_result ) {
      $c->stash( api_user => $session_result->user );
      return 1;
    }
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

  $validation->input( $c->stash->{api_json} );
  $validation->required('email')->email;
  $validation->required('password');

  return $c->api_validation_error if $validation->has_error;

  my $email = $validation->param('email');
  my $password = $validation->param('password');

  my $user_result = $c->schema->resultset('User')->find({ email => $email });
  
  if ( defined $user_result ) {
    if ( $user_result->check_password($password) ) {
      my $session_key = $user_result->generate_session;

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

  my $session_result = $c->schema->resultset('SessionToken')->find({ token => $session_key });

  if ( defined $session_result ) {
    $session_result->delete;
  }

  $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Logged Out',
  }); 
}

1;
