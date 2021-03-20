package Pear::LocalLoop::Controller::Api::Feedback;
use Mojo::Base 'Mojolicious::Controller';

has error_messages => sub {
  return {
    email => {
      required => { message => 'Email is required or not registered', status => 400 },
      in_resultset => { message => 'Email is required or not registered', status => 400, error => "required" },
    },
    feedbacktext => {
      required => { message => 'Feedback is required', status => 400 },
    },
    app_name => {
      required => { message => 'App Name is required', status => 400 },
    },
    package_name => {
      required => { message => 'Package Name is required', status => 400 },
    },
    version_code => {
      required => { message => 'Version Code is required', status => 400 },
    },
    version_number => {
      required => { message => 'Version Number is required', status => 400 },
    },
  };
};

sub post_feedback {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $user_rs = $c->schema->resultset('User');

  $validation->required('email')->in_resultset( 'email', $user_rs );
  $validation->required('feedbacktext', 'not_empty');
  $validation->required('app_name');
  $validation->required('package_name');
  $validation->required('version_code');
  $validation->required('version_number');

  return $c->api_validation_error if $validation->has_error;

  my $user = $user_rs->find({'email' => $validation->param('email')});

  $c->schema->resultset('Feedback')->create({
    user           => $user,
    feedbacktext   => $validation->param('feedbacktext'),
    app_name       => $validation->param('app_name'),
    package_name   => $validation->param('package_name'),
    version_code   => $validation->param('version_code'),
    version_number => $validation->param('version_number'),
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Thank you for your Feedback!',
  });
}

1;
