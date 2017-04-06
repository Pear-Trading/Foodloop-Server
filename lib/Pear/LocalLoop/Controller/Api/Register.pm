package Pear::LocalLoop::Controller::Api::Register;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub post_register{
  my $self = shift;

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

  my $token = $json->{token};
  if ( ! defined $token ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No token sent.',
    },
    status => 400,); #Malformed request   
  }
  elsif ( ! $self->is_token_unused($token) ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token invalid or has been used.',
    },
    status => 401,); #Unauthorized
  }

  my $username = $json->{username};
  if ( ! defined $username ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No username sent.',
    },
    status => 400,); #Malformed request   
  }
  elsif ($username eq ''){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username cannot be blank.',
    },
    status => 400,);  #Malformed request   
  }
  elsif ( ! ($self->valid_username($username))){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username can only be A-Z, a-z and 0-9 characters.',
    },
    status => 400,); #Malformed request
  }
  elsif ( $self->does_username_exist($username) ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username exists.',
    },
    status => 403,); #Forbidden
  }

  my $email = $json->{email};
  if ( ! defined $email ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No email sent.',
    },
    status => 400,); #Malformed request   
  }
  elsif ( ! $self->valid_email($email)){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Email is invalid.',
    },
    status => 400,); #Malformed request
  }
  elsif($self->does_email_exist($email)) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Email exists.',
    },
    status => 403,); #Forbidden
  }

  #TODO test to see if post code is valid.
  my $postcode = $json->{postcode};
  if ( ! defined $postcode ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No postcode sent.',
    },
    status => 400,); #Malformed request   
  }

  #TODO should we enforce password requirements.
  my $password = $json->{password};  
  if ( ! defined $password ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No password sent.',
    },
    status => 400,); #Malformed request   
  }
  my $hashedPassword = $self->generate_hashed_password($password);

  my $secondsTime = time();
  my $date = ORM::Date->new_epoch($secondsTime)->mysql_date;

  my $usertype = $json->{usertype};
      
  if ( ! defined $usertype ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No usertype sent.',
    },
    status => 400,); #Malformed request   
  }
  elsif ($usertype eq 'customer'){
    $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);

    my $age = $json->{age};
    if ( ! defined $age ){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'No age sent.',
      },
      status => 400,); #Malformed request   
    }

    my $ageForeignKey = $self->get_age_foreign_key($age);
    if ( ! defined $ageForeignKey ){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'Age range is invalid.',
      },
      status => 400,); #Malformed request
    }

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

    $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => { success => Mojo::JSON->true } );
  }
  elsif ($usertype eq 'organisation') {
    $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);

    #TODO validation on the address. Or perhaps add the organisation to a "to be inspected" list then manually check them.
    my $fullAddress = $json->{fulladdress};
    if ( ! defined $fullAddress ){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'No fulladdress sent.',
      },
      status => 400,); #Malformed request   
    }

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

    $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => { success => Mojo::JSON->true } );
  }
  else{
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => '"usertype" is invalid.',
    },
    status => 400,); #Malformed request
  }
}

1;

