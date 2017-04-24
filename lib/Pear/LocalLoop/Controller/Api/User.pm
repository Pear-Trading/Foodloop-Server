package Pear::LocalLoop::Controller::Api::User;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has error_messages => sub {
  return {
    day => {
      is_iso_datetime => { message => 'Invalid ISO8601 Datetime', status => 400 },
    },
  };
};

sub post_day {
  my $c = shift;

  my $validation = $c->validation;

  $validation->input( $c->stash->{api_json} );

  $validation->optional('day')->is_iso_datetime;

  return $c->api_validation_error if $validation->has_error;

  $c->render( json => {
    success => Mojo::JSON->true,
  });
}

1;
