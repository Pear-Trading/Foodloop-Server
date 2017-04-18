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
    fulladdress => {
      required => { message => 'No fulladdress sent.', status => 400 },
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
  $validation->required('token')->in_resultset('accounttokenname', $token_rs);

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
    $validation->required('age')->in_resultset('agerangestring', $age_rs);

  } elsif ( $usertype eq 'organisation' ) {

    #TODO validation on the address. Or perhaps add the organisation to a "to be inspected" list then manually check them.
    $validation->required('fulladdress');

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

  my $token = $validation->param('token');
  my $username = $validation->param('username');
  my $email = $validation->param('email');
  my $postcode = $validation->param('postcode');
  my $password = $validation->param('password');

  # TODO Replace with Password Column encoding
  my $hashedPassword = $c->generate_hashed_password($password);

  if ($usertype eq 'customer'){
    # TODO replace with actually using the value on the post request
    my $ageForeignKey = $c->get_age_foreign_key( $validation->param('age') );

    $c->schema->txn_do( sub {
      $c->schema->resultset('AccountToken')->find({
        accounttokenname => $token,
        used => 0,
      })->update({ used => 1 });
      $c->schema->resultset('User')->create({
        customer => {
          username => $username,
          agerange_fk => $ageForeignKey,
          postcode => $postcode,
        },
        email => $email,
        hashedpassword => $hashedPassword,
        joindate => DateTime->now,
      });
    });

  }
  elsif ($usertype eq 'organisation') {
    my $fullAddress = $validation->param('fulladdress');

    $c->schema->txn_do( sub {
      $c->schema->resultset('AccountToken')->find({
        accounttokenname => $token,
        used => 0,
      })->update({ used => 1 });
      $c->schema->resultset('User')->create({
        organisation => {
          name => $username,
          fulladdress => $fullAddress,
          postcode => $postcode,
        },
        email => $email,
        hashedpassword => $hashedPassword,
        joindate => DateTime->now,
      });
    });
  }

  return $c->render( json => { success => Mojo::JSON->true } );
}

1;
