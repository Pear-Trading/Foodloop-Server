package Pear::LocalLoop::Controller::Api::Sendmessage;
use Mojo::Base 'Mojolicious::Controller';

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

sub post_message {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $user_rs = $c->schema->resultset('User');

  #  $validation->required('email')->in_resultset( 'email', $user_rs );
  $validation->required('messagetext');

  return $c->api_validation_error if $validation->has_error;

  my $user = $user_rs->find({'email' => $validation->param('email')});
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
