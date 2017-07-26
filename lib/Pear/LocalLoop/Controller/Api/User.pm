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

sub post_account {
  my $c = shift;

  my $user = $c->stash->{api_user};
  my $user_result = $c->schema->resultset('User')->find({ user_id => $c->stash->{api_user}->id });

  if ( defined $user_result ) {
    my $email = $user_result->email;
    my $full_name;
    my $display_name;
    my $postcode;

    #Needs elsif added for trader page for this similar relevant entry
    if ( defined $user_result->customer_id ) {
      $full_name = $user_result->customer->full_name;
      $display_name = $user_result->customer->display_name;
      $postcode = $user_result->customer->postcode;
    } elsif ( defined $user_result->organisation_id ) {
      $display_name = $user_result->organisation->name;
    } else {
      return undef;
    }

    return $c->render( json => {
      success => Mojo::JSON->true,
      session_key => $session_key,
      full_name => $full_name,
      display_name => $display_name,
      email => $email,
      postcode => $postcode,
    });
  }
  return $c->render(
    json => {
      success => Mojo::JSON->false,
      message => 'Email or password is invalid.',
    },
    status => 401
  );
}

sub post_account_update {

}

1;
