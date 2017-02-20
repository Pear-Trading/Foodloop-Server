
#!/usr/bin/env perl -w
# NOT READY FOR PRODUCTION

use Mojolicious::Lite;
use Data::UUID;
use Devel::Dwarn;
use Mojo::JSON;
use Data::Dumper;
use Email::Valid;
use ORM::Date;
use Authen::Passphrase::BlowfishCrypt;
use Scalar::Util qw(looks_like_number);

# connect to database
use DBI;

my $config = plugin 'Config';

my $dbh = DBI->connect($config->{dsn},$config->{user},$config->{pass}) or die "Could not connect";
$dbh->do("PRAGMA foreign_keys = ON");
$dbh->do("PRAGMA secure_delete = ON");

my $sessionTimeSeconds = 60 * 60 * 24 * 7; #1 week.
my $sessionTokenJsonName = 'sessionToken';
my $sessionExpiresJsonName = 'sessionExpires';

Dwarn $config;

# shortcut for use in template
helper db => sub { $dbh };


any '/' => sub {
  my $self = shift;
  return $self->render(text => 'If you are seeing this, then the server is running.', success => Mojo::JSON->true);
};

#TODO this should limit the number of responses returned, when location is implemented that would be the main way of filtering.
post '/search' => sub {
  my $self = shift;
  my $userId = $self->get_active_user_id();

  my $json = $self->req->json;
  if ( ! defined $json ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'JSON is missing.',
    },
    status => 400,); #Malformed request   
  }

  my $searchName = $json->{searchName};
  if ( ! defined $searchName ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'searchName is missing.',
    },
    status => 400,); #Malformed request   
  }
  #Is blank
  elsif  ( $searchName =~ m/^\s*$/) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'searchName is blank.',
    },
    status => 400,); #Malformed request   
  }

  #Currently ingnored
  #TODO implement further. 
  my $searchLocation = $json->{searchLocation};

  my @validatedOrgs = ();
  {
    my $statementValidated = $dbh->prepare("SELECT OrganisationalId, Name, FullAddress, PostCode FROM Organisations WHERE Name LIKE ?");
    $statementValidated->execute('%'.$searchName.'%');

    while (my ($id, $name, $address, $postcode) = $statementValidated->fetchrow_array()) {
      push(@validatedOrgs, $self->create_hash($id,$name,$address,$postcode));
    }
  }

  #$self->app->log->debug( "Orgs: " . Dumper @validatedOrgs );

  my @unvalidatedOrgs = ();
  {
    my $statementUnvalidated = $dbh->prepare("SELECT PendingOrganisationId, Name, FullAddress, Postcode FROM PendingOrganisations WHERE Name LIKE ? AND UserSubmitted_FK = ?");
    $statementUnvalidated->execute('%'.$searchName.'%', $userId);

    while (my ($id, $name, $fullAddress, $postcode) = $statementUnvalidated->fetchrow_array()) {
      push(@unvalidatedOrgs, $self->create_hash($id, $name, $fullAddress, $postcode));
    }
  }
  
  $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
  return $self->render( json => {
    success => Mojo::JSON->true,
    unvalidated => \@unvalidatedOrgs,
    validated => \@validatedOrgs,
  },
  status => 200,);    

};



post '/upload' => sub {
  my $self = shift;

  my $userId = $self->get_active_user_id();

  my $json = $self->param('json');
  if ( ! defined $json ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'JSON is missing.',
    },
    status => 400,); #Malformed request   
  }

  $json = Mojo::JSON::decode_json($json);
  $self->app->log->debug( "JSON: " . Dumper $json );
  
  my $microCurrencyValue = $json->{microCurrencyValue};
  if ( ! defined $microCurrencyValue ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'microCurrencyValue is missing.',
    },
    status => 400,); #Malformed request   
  }
  #Is valid number
  elsif (! Scalar::Util::looks_like_number($microCurrencyValue)){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'microCurrencyValue does not look like a number.',
    },
    status => 400,); #Malformed request   
  }
  #Is the number range valid.
  elsif ($microCurrencyValue <= 0){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'microCurrencyValue cannot be equal to or less than zero.',
    },
    status => 400,); #Malformed request   
  }

  my $transactionAdditionType = $json->{transactionAdditionType};
  if ( ! defined $transactionAdditionType ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'transactionAdditionType is missing.',
    },
    status => 400,); #Malformed request   
  }

  my $file = $self->req->upload('file2');
  $self->app->log->debug( "file: " . Dumper $file );

  if (! defined $file) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'no file uploaded.',
    },
    status => 400,); #Malformed request   
  }

  my $ext = '.jpg';
  my $uuid = Data::UUID->new->create_str;
  my $filename = $uuid . $ext;

  #TODO Check for valid image file.
#  my $headers = $file->headers->content_type;
#  $self->app->log->debug( "content type: " . Dumper $headers );
  #Is content type wrong?
#  if ($headers ne 'image/jpeg') {
#    return $self->render( json => {
#    success => Mojo::JSON->false,
#      message => 'Wrong image extension!',
#    }, status => 400);
#  };
  
  #Add validated organisation.
  if ($transactionAdditionType == 1){

    my $addValidatedId = $json->{addValidatedId};
    if (! defined $addValidatedId){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'addValidatedId is missing.',
      },
      status => 400,); #Malformed request   
    }

    if (! $self->does_organisational_id_exist($addValidatedId)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'addValidatedId does not exist in the database.',
      },
      status => 400,); #Malformed request   
    }
  
    my $time = time();
    my $statement = $self->db->prepare("INSERT INTO Transactions (BuyerUserId_FK, SellerOrganisationId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted) VALUES (?, ?, ?, ?, ?)");
    my $rowsAdded = $statement->execute($userId, $addValidatedId, $microCurrencyValue, $filename, $time);
    
    #It was successful.
    if ($rowsAdded != 0) {
      $file->move_to('images/' . $filename);
      $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->true,
        message => 'Added transaction for validated organisation.',
      },
      status => 200,);
    }
    #TODO Untested, not quite sure how to test it.
    else {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'An unknown error occurred when adding the transaction.',
      },
      status => 500,);   
    } 
  }
  #2 and 3 are similar by the adding of a transaction at the end.
  elsif ($transactionAdditionType == 2 || $transactionAdditionType == 3){

    my $unvalidatedOrganisationId = undef;

    if ($transactionAdditionType == 2){
      $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);

      $unvalidatedOrganisationId = $json->{addUnvalidatedId};
      if (! defined $unvalidatedOrganisationId){
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'addUnvalidatedId is missing.',
        },
        status => 400,); #Malformed request   
      } 
      elsif (! Scalar::Util::looks_like_number($unvalidatedOrganisationId)){
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'addUnvalidatedId does not look like a number.',
        },
        status => 400,); #Malformed request   
      }

      my ($existsRef) = $self->db->selectrow_array("SELECT COUNT(PendingOrganisationId) FROM PendingOrganisations WHERE PendingOrganisationId = ? AND UserSubmitted_FK = ?",undef,($unvalidatedOrganisationId, $userId));
      if ($existsRef == 0) {
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'addUnvalidatedId does not exist in the database for the user.',
        },
        status => 400,); #Malformed request 
      }

    }
    #type need to add a organisation for type 3.
    else{ # ($transactionAdditionType == 3)
      $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);

      #TODO more validation.
      my $organisationName = $json->{organisationName};
      if (! defined $organisationName){
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'organisationName is missing.',
        },
        status => 400,); #Malformed request   
      }      

      #TODO validation.
      #TODO check which ones are present.
      my $streetName = $json->{streetName};
      my $town = $json->{town};
      my $postcode = $json->{postcode};

      ($unvalidatedOrganisationId) = $self->db->selectrow_array("SELECT MAX(PendingOrganisationId) FROM PendingOrganisations",undef,());
      if (defined $unvalidatedOrganisationId){
        $unvalidatedOrganisationId++;
      }
      else{
        $unvalidatedOrganisationId = 1;
      }

      my $fullAddress = "";
      
      if ( defined $streetName && ! ($streetName =~ m/^\s*$/) ){
        $fullAddress = $streetName;
      }

      if ( defined $town && ! ($town =~ m/^\s*$/) ){
        if ($fullAddress eq ""){
          $fullAddress = $town;
        }
        else{
          $fullAddress = $fullAddress . ", " . $town;          
        }

      }

      my $statement = $self->db->prepare("INSERT INTO PendingOrganisations (PendingOrganisationId, UserSubmitted_FK, TimeDateSubmitted, Name, FullAddress, Postcode) VALUES (?, ?, ?, ?, ?, ?)");
      my $rowsAdded = $statement->execute($unvalidatedOrganisationId,$userId,time(),$organisationName,$fullAddress,$postcode);

      #TODO, untested. It could not be added for some reason. Most likely race conditions.
      if ($rowsAdded == 0) {
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'An unknown error occurred when adding the transaction.',
        },
        status => 500,);   
      } 
    }


    my $statement2 = $self->db->prepare("INSERT INTO PendingTransactions (BuyerUserId_FK, PendingSellerOrganisationId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted) VALUES (?, ?, ?, ?, ?)");
    my $rowsAdded2 = $statement2->execute($userId, $unvalidatedOrganisationId, $microCurrencyValue, $filename, time());

    if ($rowsAdded2 != 0) {
      $file->move_to('images/' . $filename);
      $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->true,
        message => 'Added transaction for unvalidated organisation.',
      },
      status => 200,);    
    }
    else {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'An unknown error occurred when adding the transaction.',
      },
      status => 500,);   
    } 
  }
  else{
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'transactionAdditionType is not a valid value.',
    },
    status => 400,); #Malformed request   
  }

};

post '/register' => sub {
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
};

post '/edit' => sub {
  my $self = shift;

  my $json = $self->req->json;

  my $account = $self->get_account_by_username( $json->{username} );

  unless ( defined $account ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username not recognised, has your token expired?',
    });
# PLUG SECURITY HOLE
  } elsif ( $account->{keyused} ne 't' ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token has not been used yet!',
    });
  }
  my $insert = $self->db->prepare("UPDATE accounts SET fullname = ?, postcode = ?, age = ?, gender = ?, WHERE username = ?");
  $insert->execute(
    @{$json}{ qw/ fullname postcode age gender / }, $account->{username},
  );

  $self->render( json => { success => Mojo::JSON->true } );
};


hook before_dispatch => sub {
  my $self = shift;

  $self->remove_all_expired_sessions();

  #See if logged in.
  my $sessionToken = $self->get_session_token();
  
  #0 = no session, npn-0 is has updated session
  my $hasBeenExtended = $self->extend_session($sessionToken);

  my $path = $self->req->url->to_abs->path;

  #Has valid session
  if ($hasBeenExtended) {
    #If logged in and requestine the login page redirect to the main page.
    if ($path eq '/login') {
      #Force expire and redirect.
      $self->res->code(303);
      $self->redirect_to('/');
    }
  }
  #Has expired or did not exist in the first place and the path is not login
  elsif ($path ne '/login' &&  $path ne '/register') {
    $self->res->code(303);
    $self->redirect_to('/login');
  }
};

#FIXME placeholders
#Because of "before_dispatch" this will never be accessed unless the user is not logged in.
get '/login' => sub {
  my $self = shift;
  $self->render( text => 'This will be the login page.' );
};

#TODO set session cookie and add it to the database.
#FIXME This suffers from replay attacks, consider a challenge response. Would TLS solve this, most likely.
#SessionToken
#Because of "before_dispatch" this will never be accessed unless the user is not logged in.
post '/login' => sub {
  my $self = shift;

  my $json = $self->req->json;
  $self->app->log->debug( "\n\nStart of login");
  $self->app->log->debug( "JSON: " . Dumper $json );

  if ( ! defined $json ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No json sent.',
    },
    status => 400,); #Malformed request   
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
  elsif ( ! $self->valid_email($email) ) {  
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'email is invalid.',
    },
    status => 400,); #Malformed request
  }

  my $password = $json->{password};
  if ( ! defined $password ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No password sent.',
    },
    status => 400,); #Malformed request   
  }


  #FIXME There is a timing attack here determining if an email exists or not.
  if ($self->does_email_exist($email) && $self->check_password_email($email, $password)) {
    #Match.
    $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);

    my $userId = $self->get_userid_foreign_key($email);

    #Generates and stores
    my $hash = $self->generate_session($userId);

    $self->app->log->debug('session dump:' . Dumper ($hash));

    return $self->render( json => { 
      success => Mojo::JSON->true,
      $sessionTokenJsonName => $hash->{$sessionTokenJsonName},
      $sessionExpiresJsonName => $hash->{$sessionExpiresJsonName},
    });
  }
  else{
    #Mismatch
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Email or password is invalid.',
    },
    status => 401,); #Unauthorized request 
  }
};

post '/logout' => sub {
  my $self = shift;

  my $json = $self->req->json;
  $self->app->log->debug( "\n\nStart of logout");
  $self->app->log->debug( "JSON: " . Dumper $json );

  #If the session token exists.
  if ($self->expire_current_session()) {
    $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->true,
      message => 'you were successfully logged out.',
    }); 
  }
  #Due to the "before_dispatch" hook, this most likely will not be called. i.e. race conditions.
  #FIXME untested.
  #An invalid token was presented, most likely because it has expired.
  else {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'the session has expired or did not exist in the first place.',
    },
    status => 401,); #Unauthorized request
  }

};


post '/fetchuser' => sub {
  my $self = shift;

  my $json = $self->req->json;

  my $account = $self->get_account_by_username( $json->{username} );

  unless ( defined $account ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username not recognised, has your token expired?',
    });
# PLUG SECURITY HOLE
  } elsif ( $account->{keyused} ne 't' ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token has not been used yet!',
    });
  }

# Add stuff to send back to user below here!
  $self->render( json => { 
  success => Mojo::JSON->true,
  });
};

helper create_hash => sub{
  my ($self, $id, $name, $fullAddress, $postcode) = @_;

  my $hash = {};
  $hash->{'id'} = $id;
  $hash->{'name'} = $name;
  $hash->{'fullAddress'} = $fullAddress . ", " . $postcode;
 
  return $hash;
};



helper valid_username => sub {
  my ($self, $username) = @_;
  return ($username =~ m/^[A-Za-z0-9]+$/);
};

helper valid_email => sub {
  my ($self, $email) = @_;
  return (Email::Valid->address($email));
};

helper get_active_user_id => sub {
  my $self = shift;

  my $token = $self->get_session_token(); 
  if (! defined $token){
    return undef;
  }

  my @out = $self->db->selectrow_array("SELECT UserIdAssignedTo_FK FROM SessionTokens WHERE SessionTokenName = ?",undef,($token));
  if (! @out){
    return undef;
  }
  else{
    return $out[0];
  }
};

helper get_session_token => sub {
  my $self = shift;

  #See if logged in.
  my $sessionToken = undef;

  my $json = $self->req->json;
  if (defined $json) {
    $sessionToken = $json->{$sessionTokenJsonName};
  }

  if ( ! defined $sessionToken || $sessionToken eq "" ) {
    $sessionToken = $self->session->{$sessionTokenJsonName};
  }

  if (defined $sessionToken && $sessionToken eq "" ) {
    $sessionToken = undef;
  }

  return $sessionToken;
};


#This assumes the user has no current session on that device.
helper generate_session => sub {
  my ($self, $userId) = @_;

  my $sessionToken = $self->generate_session_token();
  my $expireDateTime = $self->session_token_expiry_date_time();

  my $insertStatement = $self->db->prepare('INSERT INTO SessionTokens (SessionTokenName, UserIdAssignedTo_FK, ExpireDateTime) VALUES (?, ?, ?)');
  my $rowsAdded = $insertStatement->execute($sessionToken, $userId, $expireDateTime);

  $self->session(expires => $expireDateTime);
  $self->session->{$sessionTokenJsonName} = $sessionToken;
  
  return {$sessionTokenJsonName => $sessionToken, $sessionExpiresJsonName => $expireDateTime};
};

helper generate_session_token => sub {
  my $self = shift;
  return Data::UUID->new->create_str();
};

helper expire_all_sessions => sub {
  my $self = shift;
  
  my $rowsDeleted = $self->db->prepare("DELETE FROM SessionTokens")->execute();
  
  return $rowsDeleted;
};

helper session_token_expiry_date_time => sub {
  my $self = shift; 
  return time() + $sessionTimeSeconds;
};

helper remove_all_expired_sessions => sub {
  my $self = shift;

  my $timeDateNow = time();

  my $removeStatement = $self->db->prepare('DELETE FROM SessionTokens WHERE ExpireDateTime < ?');
  my $rowsRemoved = $removeStatement->execute($timeDateNow);  

  return $rowsRemoved;
};


#1 = session update, 0 = there was no session or it expired.
#We assume the token has a valid structure.
helper extend_session => sub {
  my ( $self, $sessionToken ) = @_;

  my $timeDateExpire = $self->session_token_expiry_date_time();

  my $updateStatement = $self->db->prepare('UPDATE SessionTokens SET ExpireDateTime = ? WHERE SessionTokenName = ?');
  my $rowsChanges = $updateStatement->execute($timeDateExpire, $sessionToken);  

  #Has been updated.
  if ($rowsChanges != 0) {
    $self->session(expires => $timeDateExpire);
    return 1;
  } 
  else {
    $self->session(expires => 1);
    return 0;
  }
};

helper get_session_expiry => sub {
  my ( $self, $sessionToken ) = @_;

  my ( $expireTime ) = $self->db->selectrow_array("SELECT ExpireDateTime FROM SessionTokens WHERE SessionTokenName = ?", undef, ($sessionToken));

  return $expireTime;

};

#True for session was expire, false there was no session to expire.
helper expire_current_session => sub {
  my $self = shift;

  my $sessionToken = $self->get_session_token();

  my $removeStatement = $self->db->prepare('DELETE FROM SessionTokens WHERE SessionTokenName = ?');
  my $rowsRemoved = $removeStatement->execute($sessionToken);  

  $self->session(expires => 1);
  $self->session->{$sessionTokenJsonName} = $sessionToken;

  return $rowsRemoved != 0;
};

#Return true if and only if the token exists and has not been used.
helper is_token_unused => sub {
  my ( $self, $token ) = @_;

  my ( $out ) = $self->db->selectrow_array("SELECT COUNT(AccountTokenId) FROM AccountTokens WHERE AccountTokenName = ? AND Used = 0", undef, ($token));

  return $out != 0;

};

#Return true if and only if the token exists and has not been used.
helper does_organisational_id_exist => sub {
  my ( $self, $organisationalId ) = @_;

  my ( $out ) = $self->db->selectrow_array("SELECT COUNT(OrganisationalId) FROM Organisations WHERE OrganisationalId = ?", undef, ($organisationalId));
  return $out != 0;
};

helper get_age_foreign_key => sub {
  my ( $self, $ageString ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT AgeRangeId FROM AgeRanges WHERE AgeRangeString = ?", undef, ($ageString));
  return $out;
};

helper get_userid_foreign_key => sub {
  my ( $self, $email ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT UserId FROM Users WHERE Email = ?", undef, ($email));
  return $out;
  
};


helper does_username_exist => sub {
  my ( $self, $username ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT COUNT(UserName) FROM Customers WHERE UserName = ?", {}, ($username));
  return $out != 0;
};

helper does_email_exist => sub {
  my ( $self, $email ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT COUNT(Email) FROM Users WHERE Email = ?", {}, ($email));
  return $out != 0;
};

helper set_token_as_used => sub {
  my ( $self, $token ) = @_;

  #Return true if and only if the token exists and has not been used.
  my $statement = $self->db->prepare("UPDATE AccountTokens SET Used = 1 WHERE AccountTokenName = ? AND Used = 0 ");
  my $rows = $statement->execute($token);

  #print '-set_token_as_used-'.(Dumper($rows))."-\n";

  return $rows != 0;
};

helper generate_hashed_password => sub {
  my ( $self, $password ) = @_;

  my $ppr = Authen::Passphrase::BlowfishCrypt->new(
    cost => 8, salt_random => 1,
    passphrase => $password);
  return $ppr->as_crypt;

};
 
# We assume the user already exists.
helper check_password_email => sub{
  my ( $self, $email, $password) = @_;

  my ($hashedPassword) = $self->db->selectrow_array("SELECT HashedPassword FROM Users WHERE Email = ?", undef, ($email));
  my $ppr = Authen::Passphrase::BlowfishCrypt->from_crypt($hashedPassword);

  return $ppr->match($password);
};

app->start;
