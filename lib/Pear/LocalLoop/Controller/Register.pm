package Pear::LocalLoop::Controller::Register;
use Mojo::Base 'Mojolicious::Controller';

use DateTime;

has error_messages => sub {
  return {
    name => 'Full Name is required',
    email => 'Email Address is required, and must be a valid address that is not already registered',
    password => 'Password is required, and must match the Confirmation field',
    postcode => 'Postcode is required, and must be a valid UK Postcode',
    token => 'Token is required, and must be a valid, unused token',
    agerange => 'Age Range is required, and must be a selection from the drop-down',
    unknown => 'Sorry, there was a problem registering! Have you already registered?',
  };
};

sub index {
  my $c = shift;

  my $agerange_rs = $c->schema->resultset('AgeRange');
  $agerange_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $c->stash( ageranges => [ $agerange_rs->all ], form_data => {}, error => undef );
}

sub register {
  my $c = shift;
  my $validation = $c->validation;

  $validation->required('name');
  $validation->required('password')->equal_to('password2');
  $validation->required('postcode')->postcode;

  my $user_rs = $c->schema->resultset('User');
  $validation->required('email')->email->not_in_resultset('email', $user_rs);

  my $token_rs = $c->schema->resultset('AccountToken')->search_rs({used => 0});
  $validation->required('token')->in_resultset('accounttokenname', $token_rs);

  my $age_rs = $c->schema->resultset('AgeRange');
  $validation->required('agerange')->in_resultset('agerangeid', $age_rs);

  my @error_messages;
  if ( $validation->has_error ) {
    my $failed_vals = $validation->failed;
    @error_messages = map {$c->error_messages->{ $_ } } @$failed_vals;
  } else {
    my $new_user = $c->schema->resultset('User')->find_or_new({
      email => $validation->param('email'),
      hashedpassword => $validation->param('password'),
      joindate => DateTime->now(),
      customer => {
        username => $validation->param('name'),
        postcode => $validation->param('postcode'),
        agerange_fk => $validation->param('agerange'),
      },
    });
    if ( $new_user->in_storage ) {
      @error_messages = ( $c->error_messages->{unknown} );
    } else {
      $new_user->insert;
    }
  }

  if ( scalar @error_messages ) {
    $age_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    $c->stash(
      error => \@error_messages,
      ageranges => [ $age_rs->all ],
      form_data => {
        name => $validation->param('name'),
        email => $validation->param('email'),
        postcode => $validation->param('postcode'),
        token => $validation->param('token'),
        agerange => $validation->param('agerange'),
      }
    );
    $c->render( template => 'register/index' );
  } else {
    $c->flash( success => 'Registered Successfully, please log in' );
    $c->redirect_to('/');
  }
}

1;
