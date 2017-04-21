package Pear::LocalLoop::Controller::Api::Register;
use Mojo::Base 'Mojolicious::Controller';
use DateTime;

has error_messages => sub {
  return {
    token => {
      required => { message => 'No token sent.', status => 400 },
      in_resultset => { message => 'Token invalid or has been used.', status => 401 },
    },
    username => {
      required => { message => 'No username sent or was blank.', status => 400 },
      like => { message => 'Username can only be A-Z, a-z and 0-9 characters.', status => 400 },
      not_in_resultset => { message => 'Username exists.', status => 403 },
    },
    email => {
      required => { message => 'No email sent.', status => 400 },
      email => { message => 'Email is invalid.', status => 400 },
      not_in_resultset => { message => 'Email exists.', status => 403 },
    },
    postcode => {
      required => { message => 'No postcode sent.', status => 400 },
    },
    password => {
      required => { message => 'No password sent.', status => 400 },
    },
    usertype => {
      required => { message => 'No usertype sent.', status => 400 },
      in => { message => '"usertype" is invalid.', status => 400 },
    },
    age => {
      required => { message => 'No age sent.', status => 400 },
      in_resultset => { message => 'Age range is invalid.', status => 400 },
    },
    street_name => {
      required => { message => 'No street_name sent.', status => 400 },
    },
    town => {
      required => { message => 'No town sent.', status => 400 },
    },
  };
};

sub post_register{
  my $c = shift;

  my $validation = $c->validation;

  my $json = $c->req->json;

  if ( ! defined $json ){
    return $c->render( json => {
      success => Mojo::JSON->false,
      message => 'No json sent.',
    },
    status => 400,); #Malformed request   
  }
  $validation->input( $json );

  my $token_rs = $c->schema->resultset('AccountToken')->search_rs({used => 0});
  $validation->required('token')->in_resultset('name', $token_rs);

  my $customer_rs = $c->schema->resultset('Customer');
  $validation->required('username')->like(qr/^[A-Za-z0-9]+$/)->not_in_resultset('username', $customer_rs);

  my $user_rs = $c->schema->resultset('User');
  $validation->required('email')->email->not_in_resultset('email', $user_rs);

  #TODO test to see if post code is valid.
  $validation->required('postcode');

  #TODO should we enforce password requirements.
  $validation->required('password');

  $validation->required('usertype')->in('customer', 'organisation');

  my $usertype = $validation->param('usertype') || '';

  if ( $usertype eq 'customer' ) {

    my $age_rs = $c->schema->resultset('AgeRange');
    $validation->required('age')->in_resultset('id', $age_rs);

  } elsif ( $usertype eq 'organisation' ) {

    $validation->required('street_name');
    $validation->required('town');

  }

  if ( $validation->has_error ) {
    my $failed_vals = $validation->failed;
    for my $val ( @$failed_vals ) {
      my $check = shift @{ $validation->error($val) };
      return $c->render(
        json => {
          success => Mojo::JSON->false,
          message => $c->error_messages->{$val}->{$check}->{message},
        },
        status => $c->error_messages->{$val}->{$check}->{status},
      );
    }
  }

  if ($usertype eq 'customer'){

    $c->schema->txn_do( sub {
      $c->schema->resultset('AccountToken')->find({
        name => $validation->param('token'),
        used => 0,
      })->update({ used => 1 });
      $c->schema->resultset('User')->create({
        customer => {
          username     => $validation->param('username'),
          age_range_id => $validation->param('age'),
          postcode     => $validation->param('postcode'),
        },
        email    => $validation->param('email'),
        password => $validation->param('password'),
      });
    });

  }
  elsif ($usertype eq 'organisation') {
    my $fullAddress = $validation->param('fulladdress');

    $c->schema->txn_do( sub {
      $c->schema->resultset('AccountToken')->find({
        name => $validation->param('token'),
        used => 0,
      })->update({ used => 1 });
      $c->schema->resultset('User')->create({
        organisation => {
          name        => $validation->param('username'),
          street_name => $validation->param('street_name'),
          town        => $validation->param('town'),
          postcode    => $validation->param('postcode'),
        },
        email    => $validation->param('email'),
        password => $validation->param('password'),
      });
    });
  }

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Registered Successfully',
  });
}

1;
