package Pear::LocalLoop::Controller::Api::Register;
use Mojo::Base 'Mojolicious::Controller';
use ORM::Date;
use Data::Dumper;

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
  my $self = $c;

  my $validation = $c->validation;

  my $json = $self->req->json;
  $self->app->log->debug( "\n\nStart of register");
  $self->app->log->debug( "JSON: " . Dumper $json );

  if ( ! defined $json ){
    $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
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

  my $hashedPassword = $self->generate_hashed_password($password);

  my $secondsTime = time();
  my $date = ORM::Date->new_epoch($secondsTime)->mysql_date;

  if ($usertype eq 'customer'){
    my $ageForeignKey = $self->get_age_foreign_key( $validation->param('age') );

    #TODO this will go away with a transaction, when we move this bit to dbic schema code
    #TODO UNTESTED as it's hard to simulate.
    #Token is no longer valid race condition.
    if ( ! $self->set_token_as_used($token) ){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'Token no longer is accepted.',
      },
      status => 500,); #Internal server error. Racecondition
    }
  

    my ($idToUse) = $self->db->selectrow_array("SELECT MAX(CustomerId) FROM Customers");
    if (defined $idToUse){
      $idToUse++;
    }
    else{
      $idToUse = 1;
    }

    #TODO Race condition here.
    my $insertCustomer = $self->db->prepare("INSERT INTO Customers (CustomerId, UserName, AgeRange_FK, PostCode) VALUES (?, ?, ?, ?)");
    my $rowsInsertedCustomer = $insertCustomer->execute($idToUse, $username, $ageForeignKey, $postcode);
    my $insertUser = $self->db->prepare("INSERT INTO Users (CustomerId_FK, Email, JoinDate, HashedPassword) VALUES (?, ?, ?, ?)");
    my $rowsInsertedUser = $insertUser->execute($idToUse, $email, $date, $hashedPassword);

    return $self->render( json => { success => Mojo::JSON->true } );
  }
  elsif ($usertype eq 'organisation') {
    #TODO validation on the address. Or perhaps add the organisation to a "to be inspected" list then manually check them.
    my $fullAddress = $validation->param('fulladdress');

    # TODO This will go away with transactioning
    #TODO UNTESTED as it's hard to simulate. 
    #Token is no longer valid race condition.
    if ( ! $self->set_token_as_used($token) ){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'Token no longer is accepted.',
      },
      status => 500,); #Internal server error. Racecondition
    }

    my $idToUse = $self->db->selectrow_array("SELECT MAX(OrganisationalId) FROM Organisations");
    if (defined $idToUse){
      $idToUse++;
    }
    else{
      $idToUse = 1;
    }


    #TODO Race condition here.
    my $insertOrganisation = $self->db->prepare("INSERT INTO Organisations (OrganisationalId, Name, FullAddress, PostCode) VALUES (?, ?, ?, ?)");
    my $rowsInsertedOrganisation = $insertOrganisation->execute($idToUse, $username, $fullAddress, $postcode);
    my $insertUser = $self->db->prepare("INSERT INTO Users (OrganisationalId_FK, Email, JoinDate, HashedPassword) VALUES (?, ?, ?, ?)");
    my $rowsInsertedUser = $insertUser->execute($idToUse, $email, $date, $hashedPassword);

    return $self->render( json => { success => Mojo::JSON->true } );
  }
}

1;

