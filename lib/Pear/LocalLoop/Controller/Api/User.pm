package Pear::LocalLoop::Controller::Api::User;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has error_messages => sub {
  return {
    day => {
      is_iso_datetime => { message => 'Invalid ISO8601 Datetime', status => 400 },
    },
    name => {
      required => { message => 'No name sent or was blank.', status => 400 },
    },
    display_name => {
      required => { message => 'No display name sent or was blank.', status => 400 },
    },
    full_name => {
      required => { message => 'No full name sent or was blank.', status => 400 },
    },
    email => {
      required => { message => 'No email sent.', status => 400 },
      email => { message => 'Email is invalid.', status => 400 },
    },
    postcode => {
      required => { message => 'No postcode sent.', status => 400 },
      postcode => { message => 'Postcode is invalid', status => 400 },
    },
    password => {
      required => { message => 'No password sent.', status => 400 },
    },
    street_name => {
      required => { message => 'No street name sent.', status => 400 },
    },
    town => {
      required => { message => 'No town/city sent.', status => 400 },
    },
    sector => {
      required => { message => 'No sector sent.', status => 400 },
    },
  };
};

sub post_account {
  my $c = shift;

  my $user = $c->stash->{api_user};
  my $user_result = $c->schema->resultset('User')->find({ id => $c->stash->{api_user}->id });

  if ( defined $user_result ) {
    my $email = $user_result->email;

    if ( $user_result->type eq 'customer' ) {
      my $customer = $user_result->entity->customer;
      my $full_name    = $customer->full_name;
      my $display_name = $customer->display_name;
      my $postcode     = $customer->postcode;
      return $c->render( json => {
        success => Mojo::JSON->true,
        full_name => $full_name,
        display_name => $display_name,
        email => $email,
        postcode => $postcode,
        location => {
          latitude => (defined $customer->latitude ? $customer->latitude * 1 : undef),
          longitude => (defined $customer->longitude ? $customer->longitude * 1 : undef),
        },
      });
    } elsif ( $user_result->type eq 'organisation' ) {
      my $organisation = $user_result->entity->organisation;
      my $name        = $organisation->name;
      my $postcode    = $organisation->postcode;
      my $street_name = $organisation->street_name;
      my $town        = $organisation->town;
      my $sector      = $organisation->sector;
      return $c->render( json => {
        success => Mojo::JSON->true,
        town => $town,
        name => $name,
        sector => $sector,
        street_name => $street_name,
        email => $email,
        postcode => $postcode,
        location => {
          latitude => (defined $organisation->latitude ? $organisation->latitude * 1 : undef),
          longitude => (defined $organisation->longitude ? $organisation->longitude * 1 : undef),
        },
      });
    } else {
      return $c->render(
        json => {
          success => Mojo::JSON->false,
          message => 'Invalid Server Error.',
        },
        status => 500
      );
    }

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
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->required('password');

  return $c->api_validation_error if $validation->has_error;

  if ( ! $user->check_password($validation->param('password')) ) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => 'password is invalid.',
      },
      status => 401
    );
  }

  my $user_rs = $c->schema->resultset('User')->search({
    id => { "!=" => $user->id },
  });

  $validation->required('email')->not_in_resultset( 'email', $user_rs );
  $validation->required('postcode')->postcode;
  $validation->optional('new_password');

  if ( $user->type eq 'customer' ) {
    $validation->required('display_name');
    $validation->required('full_name');
  } elsif ( $user->type eq 'organisation' ) {
    $validation->required('name');
    $validation->required('street_name');
    $validation->required('town');
    $validation->required('sector');
  }

  return $c->api_validation_error if $validation->has_error;

  my $location = $c->get_location_from_postcode(
    $validation->param('postcode'),
    $user->type,
  );

  if ( $user->type eq 'customer' ){

    $c->schema->txn_do( sub {
      $user->entity->customer->update({
        full_name     => $validation->param('full_name'),
        display_name  => $validation->param('display_name'),
        postcode      => $validation->param('postcode'),
        ( defined $location ? ( %$location ) : ( latitude => undef, longitude => undef ) ),
      });
      $user->update({
        email => $validation->param('email'),
        ( defined $validation->param('new_password') ? ( password => $validation->param('new_password') ) : () ),
      });
    });

  }
  elsif ( $user->type eq 'organisation' ) {

    $c->schema->txn_do( sub {
      $user->entity->organisation->update({
        name        => $validation->param('name'),
        street_name => $validation->param('street_name'),
        town        => $validation->param('town'),
        sector      => $validation->param('sector'),
        postcode    => $validation->param('postcode'),
        ( defined $location ? ( %$location ) : ( latitude => undef, longitude => undef ) ),
      });
      $user->update({
        email        => $validation->param('email'),
        ( defined $validation->param('new_password') ? ( password => $validation->param('new_password') ) : () ),
      });
    });
  }

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Edited Account Successfully',
  });
}

1;
