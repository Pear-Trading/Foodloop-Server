package Pear::LocalLoop::Controller::Api::Register;
use Mojo::Base 'Mojolicious::Controller';
use DateTime;

use Geo::UK::Postcode::Regex;

has error_messages => sub {
  return {
    token => {
      required => { message => 'No token sent.', status => 400 },
      in_resultset => { message => 'Token invalid or has been used.', status => 401 },
    },
    name => {
      required => { message => 'No organisation name sent or was blank.', status => 400 },
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
      not_in_resultset => { message => 'Email already in use.', status => 403 },
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
    year_of_birth => {
      required => { message => 'No year of birth sent.', status => 400 },
      number => { message => 'year of birth is invalid', status => 400 },
      gt_num => { message => 'year of birth must be within last 150 years', status => 400 },
      lt_num => { message => 'year of birth must be atleast 10 years ago', status => 400 },
    },
    street_name => {
      required => { message => 'No street name sent.', status => 400 },
    },
    town => {
      required => { message => 'No town/city sent.', status => 400 },
    },
  };
};

sub post_register {
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
    my $year = DateTime->now->year;
    $validation->required('year_of_birth')->number->gt_num($year - 150)->lt_num($year - 10);
  } elsif ( $usertype eq 'organisation' ) {
    $validation->required('name');
    $validation->required('street_name');
    $validation->required('town');
    $validation->required('sector');
  }

  return $c->api_validation_error if $validation->has_error;

  my $location = $c->get_location_from_postcode(
    $validation->param('postcode'),
    $usertype,
  );

  if ($usertype eq 'customer'){

    $c->schema->txn_do( sub {
      $c->schema->resultset('AccountToken')->find({
        name => $validation->param('token'),
        used => 0,
      })->update({ used => 1 });

      $c->schema->resultset('Entity')->create({
        customer => {
          full_name     => $validation->param('full_name'),
          display_name  => $validation->param('display_name'),
          year_of_birth => $validation->param('year_of_birth'),
          postcode      => $validation->param('postcode'),
          ( defined $location ? ( %$location ) : () ),
        },
        user => {
          email    => $validation->param('email'),
          password => $validation->param('password'),
        },
        type => 'customer',
      });
    });

  }
  elsif ($usertype eq 'organisation') {

    $c->schema->txn_do( sub {
      $c->schema->resultset('AccountToken')->find({
        name => $validation->param('token'),
        used => 0,
      })->update({ used => 1 });
      $c->schema->resultset('Entity')->create({
        organisation => {
          name        => $validation->param('name'),
          street_name => $validation->param('street_name'),
          town        => $validation->param('town'),
          sector      => $validation->param('sector'),
          postcode    => $validation->param('postcode'),
          ( defined $location ? ( %$location ) : () ),
        },
        user => {
          email        => $validation->param('email'),
          password     => $validation->param('password'),
        },
        type => 'organisation',
      });
    });
  }

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Registered Successfully',
  });
}

1;
