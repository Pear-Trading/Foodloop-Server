package Pear::LocalLoop::Controller::Api::Register;
use Mojo::Base 'Mojolicious::Controller';
use DateTime;

has error_messages => sub {
  return {
    token => {
      required => { message => 'No token sent.', status => 400 },
      in_resultset => { message => 'Token invalid or has been used.', status => 401 },
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
    usertype => {
      required => { message => 'No usertype sent.', status => 400 },
      in => { message => '"usertype" is invalid.', status => 400 },
    },
    age_range => {
      required => { message => 'No age_range sent.', status => 400 },
      number => { message => 'age_range is invalid', status => 400 },
      in_resultset => { message => 'age_range is invalid.', status => 400 },
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
  $validation->input( $c->stash->{api_json} );

  my $token_rs = $c->schema->resultset('AccountToken')->search_rs({used => 0});
  $validation->required('token')->in_resultset('name', $token_rs);

  my $user_rs = $c->schema->resultset('User');
  $validation->required('email')->email->not_in_resultset('email', $user_rs);
  $validation->required('password');

  $validation->required('postcode')->postcode;
  $validation->required('usertype')->in('customer', 'organisation');

  my $usertype = $validation->param('usertype') || '';

  if ( $usertype eq 'customer' ) {
    $validation->required('display_name');
    $validation->required('full_name');
    my $age_rs = $c->schema->resultset('AgeRange');
    $validation->required('age_range')->number->in_resultset('id', $age_rs);
  } elsif ( $usertype eq 'organisation' ) {
    $validation->required('name');
    $validation->required('street_name');
    $validation->required('town');
  }

  return $c->api_validation_error if $validation->has_error;

  if ($usertype eq 'customer'){

    $c->schema->txn_do( sub {
      $c->schema->resultset('AccountToken')->find({
        name => $validation->param('token'),
        used => 0,
      })->update({ used => 1 });
      $c->schema->resultset('User')->create({
        customer => {
          full_name    => $validation->param('full_name'),
          display_name => $validation->param('display_name'),
          age_range_id => $validation->param('age_range'),
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
          name        => $validation->param('name'),
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
