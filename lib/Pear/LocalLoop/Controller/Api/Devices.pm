package Pear::LocalLoop::Controller::Api::Devices;
use Mojo::Base 'Mojolicious::Controller';
use LWP::UserAgent;
use JSON;
use Mojo::File;

has error_messages => sub {
  return {
    token => {
      required => { message => 'Token is required', status => 400 },
      not_in_resultset => { message => 'Token already in database', status => 400 },
    },
    email => {
      required => { message => 'User email is required', status => 400 },
      in_resultset => { message => 'User email not recognised', status => 400 },
    },
  };
};

sub check_token {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  $validation->required('token');

  my $token = $validation->param('token');
  my $token_rs = $c->schema->resultset('DeviceToken')->search({'token' => $token});

  if ($token_rs->count > 0) {
    return $c->render( json => {
      exists => Mojo::JSON->true
    });
  } else {
    return $c->render( json => {
      exists => Mojo::JSON->false
    });
  }
}

sub add_token {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  
  my $token_rs = $c->schema->resultset('DeviceToken');
  my $user_rs = $c->schema->resultset('User');
  
  # TODO: validate that prexisting tokens are connected to the logged-in user
  $validation->required('email')->in_resultset( 'email', $user_rs );  
  $validation->required('token')->not_in_resultset( 'token', $token_rs );

  return $c->api_validation_error if $validation->has_error;

  my $user = $user_rs->find({'email' => $validation->param('email')});
  
  my $token = $validation->param('token');

  $user->create_related(
    'device_tokens',
    {
      token   => $token,
    }
  );
  
  my $end_point = "https://iid.googleapis.com/iid/v1/${token}/rel/topics/default";

  my $path = './localspend-47012.json';
  my $json = decode_json(Mojo::File->new($path)->slurp);
  croak("No Private key in $path") if not defined $json->{server_key};
  croak("Not a service account") if $json->{type} ne 'service_account';

  my $ua = LWP::UserAgent->new();
  my $request = HTTP::Request->new('POST', $end_point);

  $request->header('Authorization' => 'key='.$json->{server_key});
  $request->header('Content-Length' => '0');
  my $response = $ua->request($request);

  if ($response->is_success) {
    my $deviceToken = $c->schema->resultset('DeviceToken')->find({'token' => $token});
    my $topic = $c->schema->resultset('Topic')->find({'name' => 'default'});

    $deviceToken->create_related(
      'device_subscriptions',
      {
        topic => $topic    
      }
    );

    return $c->render( json => {
      success => Mojo::JSON->true,
      message => 'Device registered successfully!',
    });
  } elsif ($response->is_error) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => [
          $response->decoded_content,
        ],
        error => 'subscription_error',
      },
      status => $response->code,
    ); 
  }
}

sub get_tokens {
  my $c = shift;
  
  my $token_rs = $c->schema->resultset('DeviceToken');

  my @tokens = (
    map {{
      id => $_->id,
      user => $c->schema->resultset('User')->find({'id' => $_->user_id})->entity->customer->display_name,
      token => $_->token,
    }} $token_rs->all
  );
  
  return $c->render( json => {
    success => Mojo::JSON->true,
    tokens => \@tokens,
  });
}

1;
