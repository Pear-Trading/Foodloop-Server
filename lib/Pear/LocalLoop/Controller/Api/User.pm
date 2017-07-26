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
      required => { message => 'No name sent or was blank.', status => 400 },
    },
    full_name => {
      required => { message => 'No name sent or was blank.', status => 400 },
    },
    email => {
      required => { message => 'No email sent.', status => 400 },
      email => { message => 'Email is invalid.', status => 400 },
      not_in_resultset => { message => 'Email exists.', status => 403 },
    },
    postcode => {
      required => { message => 'No postcode sent.', status => 400 },
      postcode => { message => 'Postcode is invalid', status => 400 },
    },
    password => {
      required => { message => 'No password sent.', status => 400 },
    },
    street_name => {
      required => { message => 'No street_name sent.', status => 400 },
    },
    town => {
      required => { message => 'No town sent.', status => 400 },
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
  my $c = shift;

  my $user = $c->stash->{api_user};
  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $user_result = $c->schema->resultset('User');

  $validation->required('email')->in_resultset( 'email', $user_result );
  $validation->required('postcode')->postcode;

  if ( defined $user_result->customer_id) ) {
    $validation->required('display_name');
    $validation->required('full_name');
  } elsif ( defined $user_result->customer_id ) {
    $validation->required('name');
    $validation->required('street_name');
    $validation->required('town');
  }

  return $c->api_validation_error if $validation->has_error;

  if ($usertype eq 'customer'){

    $c->schema->txn_do( sub {
      my $customer = $c->schema->resultset('Customer')->find({
        user_id => $c->stash->{api_user}->id
      })->update({
        full_name     => $validation->param('full_name'),
        display_name  => $validation->param('display_name'),
        postcode      => $validation->param('postcode'),
      });
      $c->schema->resultset('User')->find({
        user_id => $c->stash->{api_user}->id
      })->update({
        email        => $validation->param('email'),
        password     => $validation->param('new_password')
      });
    });

  }
  elsif ($usertype eq 'organisation') {
    my $fullAddress = $validation->param('fulladdress');

    $c->schema->txn_do( sub {
      my $organisation = $c->schema->resultset('Organisation')->find({
        user_id => $c->stash->{api_user}->id
      })->update({
        name        => $validation->param('name'),
        street_name => $validation->param('street_name'),
        town        => $validation->param('town'),
        postcode    => $validation->param('postcode'),
      });
      $c->schema->resultset('User')->find({
        user_id => $c->stash->{api_user}->id
      })->update({
        # customer => $customer,
        email        => $validation->param('email'),
        password     => $validation->param('new_password')
      });
    });
  }

  $c->schema->resultset('Customer')->find({
    user_id => $c->stash->{api_user}->id
  })->update({
    full_name     => $validation->param('full_name'),
    display_name  => $validation->param('display_name'),
    postcode      => $validation->param('postcode'),
  });
  $c->schema->resultset('User')->find({
    user_id => $c->stash->{api_user}->id
  })->update({
    # organisation => $organisation,
    email        => $validation->param('email'),
    password     => $validation->param('new_password')
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Edited Account Successfully',
  });
}

1;
