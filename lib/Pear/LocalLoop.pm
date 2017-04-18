package Pear::LocalLoop;

use Mojo::Base 'Mojolicious';
use Data::UUID;
use Mojo::JSON;
use Email::Valid;
use Authen::Passphrase::BlowfishCrypt;
use Scalar::Util qw(looks_like_number);
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

  $self->plugin('Pear::LocalLoop::Plugin::Validators');

  $self->plugin('Authentication' => {
    'load_user' => sub {
      my ( $c, $user_id ) = @_;
      return $c->schema->resultset('User')->find($user_id);
    },
    'validate_user' => sub {
      my ( $c, $email, $password, $args) = @_;
      my $user = $c->schema->resultset('User')->find({email => $email});
      return $c->check_password_email($email, $password) ? $user->userid : undef;
    },
  });

  # shortcut for use in template
  $self->helper( db => sub { $self->app->schema->storage->dbh });
  $self->helper( schema => sub { $self->app->schema });


  my $r = $self->routes;
  $r->get('/')->to('root#index');
  $r->post('/')->to('root#auth_login');
  $r->get('/register')->to('register#index');
  $r->post('/register')->to('register#register');
  $r->any('/logout')->to('root#auth_logout');
  my $api = $r->under('/api' => sub {
    my $c = shift;

    #See if logged in.
    my $sessionToken = $c->get_session_token();

    #0 = no session, npn-0 is has updated session
    my $hasBeenExtended = $c->extend_session($sessionToken);

    my $path = $c->req->url->to_abs->path;

    #Has valid session
    if ($hasBeenExtended) {
      #If logged in and requestine the login page redirect to the main page.
      if ($path eq '/api/login') {
        #Force expire and redirect.
        $c->res->code(303);
        $c->redirect_to('/api');
        return undef;
      }
    }
    #Has expired or did not exist in the first place and the path is not login
    elsif ($path ne '/api/login' &&  $path ne '/api/register') {
      $c->res->code(303);
      $c->redirect_to('/api/login');
      return undef;
    }
    return 1;
  });

  $api->post("/register")->to('api-register#post_register');
  $api->post("/upload")->to('api-upload#post_upload');
  $api->post("/search")->to('api-upload#post_search');
  $api->post("/admin-approve")->to('api-admin#post_admin_approve');
  $api->post("/admin-merge")->to('api-admin#post_admin_merge');
  $api->get("/login")->to('api-auth#get_login');
  $api->post("/login")->to('api-auth#post_login');
  $api->post("/logout")->to('api-auth#post_logout');
  $api->post("/edit")->to('api-api#post_edit');
  $api->post("/fetchuser")->to('api-api#post_fetchuser');
  $api->post("/user-history")->to('api-user#post_user_history');

  $api->any( '/' => sub {
    my $self = shift;
    return $self->render(json => { success => Mojo::JSON->true });
  });

  my $admin_routes = $r->under('/admin')->to('admin#under');

  $admin_routes->get('/')->to('admin#home');
  $admin_routes->get('/tokens')->to('admin-tokens#index');
  $admin_routes->post('/tokens')->to('admin-tokens#create');
  $admin_routes->get('/tokens/:id')->to('admin-tokens#read');
  $admin_routes->post('/tokens/:id')->to('admin-tokens#update');
  $admin_routes->post('/tokens/:id/delete')->to('admin-tokens#delete');
  $admin_routes->get('/users')->to('admin-users#index');
  $admin_routes->post('/users')->to('admin-users#create');
  $admin_routes->get('/users/:id')->to('admin-users#read');
  $admin_routes->post('/users/:id')->to('admin-users#update');
  $admin_routes->post('/users/:id/delete')->to('admin-users#delete');

  my $user_routes = $r->under('/')->to('root#under');

  $user_routes->get('/home')->to('root#home');

$self->hook( before_dispatch => sub {
  my $self = shift;

  $self->res->headers->header('Access-Control-Allow-Origin' => '*') if $self->app->mode eq 'development';

  $self->remove_all_expired_sessions();
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
    my $c = shift;
    my $self = $c;

    my $sessionToken = $self->get_session_token();

    $c->schema->resultset('SessionToken')->search({
      sessiontokenname => $sessionToken,
    })->delete_all;

    $self->session(expires => 1);
    $self->session->{$self->app->config->{sessionTokenJsonName}} = $sessionToken;

    return 1;
  });

  $self->helper(is_token_unused => sub {
    my ( $c, $token ) = @_;
    return defined $c->schema->resultset('AccountToken')->find({
      accounttokenname => $token,
      used => 0,
    });
  });

  $self->helper(does_organisational_id_exist => sub {
    my ( $c, $org_id ) = @_;
    return defined $c->schema->resultset('Organisation')->find({ organisationalid => $org_id });
  });

  $self->helper(get_age_foreign_key => sub {
    my ( $c, $age_string ) = @_;
    my $age_range = $c->schema->resultset('AgeRange')->find({ agerangestring => $age_string });
    return defined $age_range ? $age_range->agerangeid : undef;
  });

  $self->helper(get_userid_foreign_key => sub {
    my ( $c, $email ) = @_;
    my $user = $c->schema->resultset('User')->find({ email => $email });
    return defined $user ? $user->userid : undef;
  });

  $self->helper(does_username_exist => sub {
    my ( $c, $username ) = @_;
    return defined $c->schema->resultset('Customer')->find({ username => $username });
  });

  $self->helper(does_email_exist => sub {
    my ( $c, $email ) = @_;
    return defined $c->schema->resultset('User')->find({ email => $email });
  });

  $self->helper(set_token_as_used => sub {
    my ( $c, $token ) = @_;
    return defined $c->schema->resultset('AccountToken')->find({
      accounttokenname => $token,
      used => 0,
    })->update({ used => 1 });
  });

  $self->helper(generate_hashed_password => sub {
    my ( $c, $password ) = @_;
    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
      cost => 8,
      salt_random => 1,
      passphrase => $password,
    );
    return $ppr->as_crypt;
  });
 
  # We assume the user already exists.
  $self->helper(check_password_email => sub {
    my ( $c, $email, $password ) = @_;
    my $user = $c->schema->resultset('User')->find({ email => $email });
    return undef unless defined $user;
    my $ppr = Authen::Passphrase::BlowfishCrypt->from_crypt($user->hashedpassword);
    return $ppr->match($password);
  });

}

1;
