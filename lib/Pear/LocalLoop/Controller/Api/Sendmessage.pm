package Pear::LocalLoop::Controller::Api::Sendmessage;
use Mojo::Base 'Mojolicious::Controller';
use LWP::UserAgent;
use JSON;
use JSON::Parse 'parse_json';
use Mojo::JWT;
use Mojo::File;
use Carp;

has error_messages => sub {
  return {
    #devicetokens => {
    #  required => { message => 'Device token is required', status => 400 },
    #  in_resultset => { message => 'Device token not found', status => 400 },
    #},
    topic => {
      required => { message => 'Topic is required', status => 400 },
    },
    sender => {
      required => { message => 'Sender name is required', status => 400 },
      in_resultset => { message => 'Sender org not found', status => 400 },
    },
    messagetext => {
      required => { message => 'Message is required', status => 400 },
    },
  };
};

=begin comment
  Credit: Peter Scott/StackOverflow
    https://stackoverflow.com/a/53357961/4580273
  Credit: jeffez/StackOverflow
    https://stackoverflow.com/q/56556438/4580273
=cut

my $jwt = create_jwt_from_path_and_scopes('./localspend-47012.json', 'email https://www.googleapis.com/auth/cloud-platform');

my $ua = LWP::UserAgent->new();

my $response = $ua->post('https://www.googleapis.com/oauth2/v4/token',
  {
    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion' => $jwt
  }
);

my $bearer_token = parse_json($response->content);

sub create_jwt_from_path_and_scopes
{
  my ( $path, $scope ) = @_;
  croak("No path provided")        if not defined $path;
  croak("$path not available")      if not -f $path;
  my $json = decode_json( Mojo::File->new($path)->slurp );
  croak("No Private key in $path") if not defined $json->{private_key};
  croak("Not a service account")   if $json->{type} ne 'service_account';
  my $jwt = Mojo::JWT->new();
  $jwt->algorithm('RS256');
  $jwt->secret($json->{private_key});

  $jwt->claims( {
      iss   => $json->{client_email},
      scope => $scope,
      aud   => 'https://www.googleapis.com/oauth2/v4/token',
      iat   => time(),
      exp   => time()+3600
  } );
  $jwt->set_iat( 1 );
  return $jwt->encode;
}

sub get_topics {
  my $c = shift;

  my $topic_rs = $c->schema->resultset('Topic');

  my @topics = (
    map {{
      id => $_->id,
      name => $_->name,
      numberOfSubscribers => $_->search_related('device_subscriptions', {'topic_id' => $_->id})->count,
    }} $topic_rs->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    topics => \@topics,
  });
}

sub post_message {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  #$validation->required('devicetokens')->in_resultset('token', $c->schema->resultset('DeviceToken'));
  $validation->required('topic');
  $validation->required('sender')->in_resultset('name', $c->schema->resultset('Organisation'));
  $validation->required('messagetext');

  return $c->api_validation_error if $validation->has_error;

  my $end_point = "https://fcm.googleapis.com/v1/projects/localspend-47012/messages:send";

  my $request = HTTP::Request->new('POST', $end_point);
  $request->header('Authorization' => "Bearer $bearer_token->{access_token}");
  $request->header('Content-Type' => 'application/json');

  $request->content(JSON::encode_json ({
    message => {
      topic => $validation->param('topic'),
      notification => {
        title => $validation->param('sender'),
        body => $validation->param('messagetext')
      },
      webpush => {
        headers => {
          urgency => 'very-low'
        },
        notification => {
          title => $validation->param('sender'),
          body => $validation->param('messagetext'),
        }
      }
    }
  }));

  my $response = $ua->request($request);

  if ($response->is_success) {
    return $c->render( json => {
      success => Mojo::JSON->true,
      message => 'Your message has been sent successfully!',
    });
  } elsif ($response->is_error) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => [
          $response->decoded_content,
          $jwt,
          $bearer_token
        ],
        error   => 'message_error',
      },
      status => $response->code,
    );
  }
}

1;
