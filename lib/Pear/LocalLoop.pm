package Pear::LocalLoop;

use Mojo::Base 'Mojolicious';
use Data::UUID;
use Mojo::JSON;
use Email::Valid;
use Authen::Passphrase::BlowfishCrypt;
use Pear::LocalLoop::Schema;

has schema => sub {
  my $c = shift;
  return Pear::LocalLoop::Schema->connect(
    $c->app->config->{dsn},
    $c->app->config->{user},
    $c->app->config->{pass},
  );
};

sub startup {
  my $self = shift;

  $self->plugin('Config', {
    default => {
      sessionTimeSeconds => 60 * 60 * 24 * 7,
      sessionTokenJsonName => 'sessionToken',
      sessionExpiresJsonName => 'sessionExpires',
    },
  });
  my $config = $self->config;

  # shortcut for use in template
  $self->helper( db => sub { $self->app->schema->storage->dbh });
  $self->helper( schema => sub { $self->app->schema });


  my $r = $self->routes;
  $r = $r->any('/api') if $self->app->mode ne 'testing';

  $r->post("/register")->to('register#post_register');
  $r->post("/upload")->to('upload#post_upload');
  $r->post("/search")->to('upload#post_search');
  $r->post("/admin-approve")->to('admin#post_admin_approve');
  $r->post("/admin-merge")->to('admin#post_admin_merge');
  $r->get("/login")->to('auth#get_login');
  $r->post("/login")->to('auth#post_login');
  $r->post("/logout")->to('auth#post_logout');
  $r->post("/edit")->to('api#post_edit');
  $r->post("/fetchuser")->to('api#post_fetchuser');
  $r->post("/user-history")->to('user#post_user_history');

  $r->any( '/' => sub {
    my $self = shift;
    return $self->render(json => { success => Mojo::JSON->true });
  });

$self->hook( before_dispatch => sub {
  my $self = shift;

  $self->app->log->debug('Before Dispatch');
  $self->res->headers->header('Access-Control-Allow-Origin' => '*') if $self->app->mode eq 'development';

  $self->remove_all_expired_sessions();

  #See if logged in.
  my $sessionToken = $self->get_session_token();
  #$self->app->log->debug( "sessionToken: " . $sessionToken);
  
  #0 = no session, npn-0 is has updated session
  my $hasBeenExtended = $self->extend_session($sessionToken);
  #$self->app->log->debug( "hasBeenExtended: " . $hasBeenExtended);

  my $path = $self->req->url->to_abs->path;

  $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);

  #Has valid session
  if ($hasBeenExtended) {
    $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);
    #If logged in and requestine the login page redirect to the main page.
    if ($path eq '/login') {
      $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);
      #Force expire and redirect.
      $self->res->code(303);
      $self->redirect_to('/');
    }
  }
  #Has expired or did not exist in the first place and the path is not login
  elsif ($path ne '/login' &&  $path ne '/register') {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    $self->res->code(303);
    $self->redirect_to('/login');
  }
  $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);
});


  $self->helper( is_admin => sub {
    my ($c, $user_id) = @_;
    my $admin = $c->schema->resultset('Administrator')->find($user_id);
    return defined $admin;
  });

  $self->helper( create_hash => sub{
    my ($self, $id, $name, $fullAddress, $postcode) = @_;

    return {
      id => $id,
      name => $name,
      fullAddress => $fullAddress . ", " . $postcode,
    }
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
    $sessionToken = $json->{$self->app->config->{sessionTokenJsonName}};
  }

  if ( ! defined $sessionToken || $sessionToken eq "" ) {
    $sessionToken = $self->session->{$self->app->config->{sessionTokenJsonName}};
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
  $self->session->{$self->app->config->{sessionTokenJsonName}} = $sessionToken;
  
  return {$self->app->config->{sessionTokenJsonName} => $sessionToken, $self->app->config->{sessionExpiresJsonName} => $expireDateTime};
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
  my $c = shift; 
  return time() + $c->app->config->{sessionTimeSeconds};
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
  $self->session->{$self->app->config->{sessionTokenJsonName}} = $sessionToken;

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
