package Pear::LocalLoop::Controller::Api::Sendmessage;
use Mojo::Base 'Mojolicious::Controller';
use LWP::UserAgent;
use JSON;
use Mojo::JWT;
use Mojo::File;
use Carp;

has error_messages => sub {
  return {
    email => {
      required => { message => 'Email is required or not registered', status => 400 },
      in_resultset => { message => 'Email is required or not registered', status => 400, error => "required" },
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

my $jwt = create_jwt_from_path_and_scopes('./localspend-47012.json', 'email https://www.googleapis.com/auth/compute');
my $ua = LWP::UserAgent->new();

my $bearer_token = $ua->post('https://www.googleapis.com/oauth2/v4/token',
  {
    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion' => $jwt
  }
);

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

sub post_message {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $user_rs = $c->schema->resultset('User');

  #  $validation->required('email')->in_resultset( 'email', $user_rs );
  $validation->required('messagetext');

  return $c->api_validation_error if $validation->has_error;

  my $user = $user_rs->find({'email' => $validation->param('email')});

  my $end_point = "https://fcm.googleapis.com/v1/projects/localspend-47012/messages:send";

  my $request = HTTP::Request->new('POST', $end_point);
  $request->header('Authorization' => "Bearer $bearer_token");
  $request->header('Content-Type' => 'application/json');

  $request->content(JSON::encode_json ({
    message => {
      token => $user->param('token'),
      notification => {
        title => 'test',
        body => 'test content'
      },
      webpush => {
        headers => {
          Urgency => 'high'
        },
        notification => {
          body => 'test content',
          requireInteraction => 'true'
        }
      }
    }
  }));

  $ua->request($request);

=begin comment
  $c->schema->resultset('Feedback')->create({
    user           => $user,
    messagetext   => $validation->param('messagetext'),
  });
=cut
  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Your message has been sent successfully!',
  });
}

1;
