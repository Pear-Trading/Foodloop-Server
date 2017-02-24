package Pear::LocalLoop;

use Mojo::Base 'Mojolicious';
use Data::UUID;
use Devel::Dwarn;
use Mojo::JSON;
use Data::Dumper;
use Email::Valid;
use ORM::Date;
use Authen::Passphrase::BlowfishCrypt;
use Scalar::Util qw(looks_like_number);
use Pear::LocalLoop::Schema;


sub startup {
  my $self = shift;

  
$self->plugin( 'Config', {
  default => {
    sessionTimeSeconds => 60 * 60 * 24 * 7,
    sessionTokenJsonName => 'sessionToken',
    sessionExpiresJsonName => 'sessionExpires',
  },
});
my $config = $self->config;

my $schema = Pear::LocalLoop::Schema->connect($config->{dsn},$config->{user},$config->{pass}) or die "Could not connect";
my $dbh = $schema->storage->dbh;
$dbh->do("PRAGMA foreign_keys = ON");
$dbh->do("PRAGMA secure_delete = ON");

my $sessionTimeSeconds = 60 * 60 * 24 * 7; #1 week.
my $sessionTokenJsonName = 'sessionToken';
my $sessionExpiresJsonName = 'sessionExpires';

Dwarn $config;

# shortcut for use in template
$self->helper( db => sub { $dbh });

my $r = $self->routes;

$r->post("/register")->to('register#post_register');

$r->post("/upload")->to('upload#post_upload');
$r->post("/search")->to('upload#post_search');

$r->post("/admin-approve")->to('admin#post_admin_approve');

$r->get("/login")->to('auth#get_login');
$r->post("/login")->to('auth#post_login');
$r->post("/logout")->to('auth#post_logout');

$r->post("/edit")->to('api#post_edit');
$r->post("/fetchuser")->to('api#post_fetchuser');


$r->any( '/' => sub {
  my $self = shift;
  return $self->render(text => 'If you are seeing this, then the server is running.', success => Mojo::JSON->true);
});


#TODO this should limit the number of responses returned, when location is implemented that would be the main way of filtering.
$r->post ('/search' => sub {
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

  #Currently ignored
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

});




$self->hook( before_dispatch => sub {
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
});


$self->helper( is_admin => sub{
  my ($self, $userId) = @_;

  my ($rowCount) = $self->db->selectrow_array("SELECT COUNT(UserId) FROM Administrators WHERE UserId = ?", undef, ($userId));

  return $rowCount != 0;
});

$self->helper( create_hash => sub{
  my ($self, $id, $name, $fullAddress, $postcode) = @_;

  my $hash = {};
  $hash->{'id'} = $id;
  $hash->{'name'} = $name;
  $hash->{'fullAddress'} = $fullAddress . ", " . $postcode;
 
  return $hash;
});



$self->helper( valid_username => sub {
  my ($self, $username) = @_;
  return ($username =~ m/^[A-Za-z0-9]+$/);
});

$self->helper(valid_email => sub {
  my ($self, $email) = @_;
  return (Email::Valid->address($email));
});

$self->helper(get_active_user_id => sub {
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
});

$self->helper(get_session_token => sub {
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
});


#This assumes the user has no current session on that device.
$self->helper(generate_session => sub {
  my ($self, $userId) = @_;

  my $sessionToken = $self->generate_session_token();
  my $expireDateTime = $self->session_token_expiry_date_time();

  my $insertStatement = $self->db->prepare('INSERT INTO SessionTokens (SessionTokenName, UserIdAssignedTo_FK, ExpireDateTime) VALUES (?, ?, ?)');
  my $rowsAdded = $insertStatement->execute($sessionToken, $userId, $expireDateTime);

  $self->session(expires => $expireDateTime);
  $self->session->{$sessionTokenJsonName} = $sessionToken;
  
  return {$sessionTokenJsonName => $sessionToken, $sessionExpiresJsonName => $expireDateTime};
});

$self->helper(generate_session_token => sub {
  my $self = shift;
  return Data::UUID->new->create_str();
});

$self->helper(expire_all_sessions => sub {
  my $self = shift;
  
  my $rowsDeleted = $self->db->prepare("DELETE FROM SessionTokens")->execute();
  
  return $rowsDeleted;
});

$self->helper(session_token_expiry_date_time => sub {
  my $self = shift; 
  return time() + $sessionTimeSeconds;
});

$self->helper(remove_all_expired_sessions => sub {
  my $self = shift;

  my $timeDateNow = time();

  my $removeStatement = $self->db->prepare('DELETE FROM SessionTokens WHERE ExpireDateTime < ?');
  my $rowsRemoved = $removeStatement->execute($timeDateNow);  

  return $rowsRemoved;
});


#1 = session update, 0 = there was no session or it expired.
#We assume the token has a valid structure.
$self->helper(extend_session => sub {
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
});

$self->helper(get_session_expiry => sub {
  my ( $self, $sessionToken ) = @_;

  my ( $expireTime ) = $self->db->selectrow_array("SELECT ExpireDateTime FROM SessionTokens WHERE SessionTokenName = ?", undef, ($sessionToken));

  return $expireTime;

});

#True for session was expire, false there was no session to expire.
$self->helper(expire_current_session => sub {
  my $self = shift;

  my $sessionToken = $self->get_session_token();

  my $removeStatement = $self->db->prepare('DELETE FROM SessionTokens WHERE SessionTokenName = ?');
  my $rowsRemoved = $removeStatement->execute($sessionToken);  

  $self->session(expires => 1);
  $self->session->{$sessionTokenJsonName} = $sessionToken;

  return $rowsRemoved != 0;
});

#Return true if and only if the token exists and has not been used.
$self->helper(is_token_unused => sub {
  my ( $self, $token ) = @_;

  my ( $out ) = $self->db->selectrow_array("SELECT COUNT(AccountTokenId) FROM AccountTokens WHERE AccountTokenName = ? AND Used = 0", undef, ($token));

  return $out != 0;

});

#Return true if and only if the token exists and has not been used.
$self->helper(does_organisational_id_exist => sub {
  my ( $self, $organisationalId ) = @_;

  my ( $out ) = $self->db->selectrow_array("SELECT COUNT(OrganisationalId) FROM Organisations WHERE OrganisationalId = ?", undef, ($organisationalId));
  return $out != 0;
});

$self->helper(get_age_foreign_key => sub {
  my ( $self, $ageString ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT AgeRangeId FROM AgeRanges WHERE AgeRangeString = ?", undef, ($ageString));
  return $out;
});

$self->helper(get_userid_foreign_key => sub {
  my ( $self, $email ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT UserId FROM Users WHERE Email = ?", undef, ($email));
  return $out;
  
});


$self->helper(does_username_exist => sub {
  my ( $self, $username ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT COUNT(UserName) FROM Customers WHERE UserName = ?", {}, ($username));
  return $out != 0;
});

$self->helper(does_email_exist => sub {
  my ( $self, $email ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT COUNT(Email) FROM Users WHERE Email = ?", {}, ($email));
  return $out != 0;
});

$self->helper(set_token_as_used => sub {
  my ( $self, $token ) = @_;

  #Return true if and only if the token exists and has not been used.
  my $statement = $self->db->prepare("UPDATE AccountTokens SET Used = 1 WHERE AccountTokenName = ? AND Used = 0 ");
  my $rows = $statement->execute($token);

  #print '-set_token_as_used-'.(Dumper($rows))."-\n";

  return $rows != 0;
});

$self->helper(generate_hashed_password => sub {
  my ( $self, $password ) = @_;

  my $ppr = Authen::Passphrase::BlowfishCrypt->new(
    cost => 8, salt_random => 1,
    passphrase => $password);
  return $ppr->as_crypt;

});
 
# We assume the user already exists.
$self->helper(check_password_email => sub{
  my ( $self, $email, $password) = @_;

  my ($hashedPassword) = $self->db->selectrow_array("SELECT HashedPassword FROM Users WHERE Email = ?", undef, ($email));
  my $ppr = Authen::Passphrase::BlowfishCrypt->from_crypt($hashedPassword);

  return $ppr->match($password);
});

}

1;
