
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

# connect to database
use DBI;

my $config = plugin 'Config';

my $dbh = DBI->connect($config->{dsn},$config->{user},$config->{pass}) or die "Could not connect";
$dbh->do("PRAGMA foreign_keys = ON");
$dbh->do("PRAGMA secure_delete = ON");

Dwarn $config;

# shortcut for use in template
helper db => sub { $dbh };

any '/' => sub {
  my $self = shift;

  $self->render(text => 'If you are seeing this, then the server is running.');
};

post '/upload' => sub {
  my $self = shift;
# Fetch parameters to write to DB
  my $key = $self->param('key');
# This will include an if function to see if key matches
  unless ($key eq $config->{key}) {
    return $self->render( json => { success => Mojo::JSON->false }, status => 403 );
  } 
  my $username = $self->param('username');
  my $company = $self->param('company');
  my $currency = $self->param('currency');
  my $file = $self->req->upload('file');
# Get image type and check extension
  my $headers = $file->headers->content_type;
# Is content type wrong?
  if ($headers ne 'image/jpeg') {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Wrong image extension!',
    });
  };
# Rewrite header data
  my $ext = '.jpg';
  my $uuid = Data::UUID->new->create_str;
  my $filename = $uuid . $ext;
# send photo to image folder on server
  $file->move_to('images/' . $filename);
# send data to foodloop db
  my $insert = $self->db->prepare('INSERT INTO foodloop (username, company, currency, filename) VALUES (?,?,?,?)');
  $insert->execute($username, $company, $currency, $filename);
  $self->render( json => { success => Mojo::JSON->true } );
  $self->render(text => 'It did not kaboom!');

};

post '/register' => sub {
  my $self = shift;

  my $json = $self->req->json;
  $self->app->log->debug( "JSON: " . Dumper $json );

  my $token = $json->{token};
  if ( ! $self->is_token_unused($token) ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token not valid or has been used.',
    },
    status => 401,); #Unauthorized
  }

  my $username = $json->{username};
  if ($username eq ''){
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username cannot be blank.',
    },
    status => 400,);  #Malformed request   
  }
  elsif ( ! ($username =~ m/^[A-Za-z0-9]+$/)){
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username can only be A-Z, a-z and 0-9 characters.',
    },
    status => 400,); #Malformed request
  }
  elsif ( $self->does_username_exist($username) ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username exists.',
    },
    status => 403,); #Forbidden
  }

  my $email = $json->{email};
  if ( ! Email::Valid->address($email)){
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Email is invalid.',
    },
    status => 400,); #Malformed request
  }
  elsif($self->does_email_exist($email)) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Email exists.',
    },
    status => 403,); #Forbidden
  }

  #TODO test to see if post code is valid.
  my $postcode = $json->{postcode};

  #TODO should we enforce password requirements.
  my $password = $json->{password};  
  my $hashedPassword = $self->generate_hashed_password($password);

  my $secondsTime = time();
  my $date = ORM::Date->new_epoch($secondsTime)->mysql_date;

  my $usertype = $json->{usertype};
      
  if ($usertype eq 'customer'){
    my $age = $json->{age};

    my $ageForeignKey = $self->get_age_foreign_key($age);
    if ( ! defined $ageForeignKey ){
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'Age range is invalid.',
      },
      status => 400,); #Malformed request
    }

    #TODO UNTESTED as it's hard to simulate.
    #Token is no longer valid race condition.
    if ( ! $self->set_token_as_used($token) ){
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
    my $fullAddress = $json->{fulladdress};

    #TODO UNTESTED as it's hard to simulate. 
    #Token is no longer valid race condition.
    if ( ! $self->set_token_as_used($token) ){
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
  else{
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

helper get_account_by_username => sub {
  my ( $self, $username ) = @_;

  return $self->db->selectrow_hashref(
    "SELECT keyused, username FROM accounts WHERE username = ?",
    {},
    $username,
  );
};

#Return true if and only if the token exists and has not been used.
helper is_token_unused => sub {
  my ( $self, $token ) = @_;

  my ( $out ) = $self->db->selectrow_array("SELECT COUNT(TokenId) FROM Tokens WHERE TokenName = ? AND Used = 0", undef, ($token));

  return $out != 0;

};

helper get_age_foreign_key => sub {
  my ( $self, $ageString ) = @_;

  my ($out) = $self->db->selectrow_array(
    "SELECT AgeRangeId FROM AgeRanges WHERE AgeRangeString = ?",
    {},
    $ageString,
  );

  return $out;
};


helper does_username_exist => sub {
  my ( $self, $username ) = @_;

  my ($out) = $self->db->selectrow_array("SELECT COUNT(UserName) FROM Customers WHERE UserName = ?", {}, ($username));
  #print "-". Dumper($out) ."-";
  
  return $out != 0;
};

helper does_email_exist => sub {
  my ( $self, $email ) = @_;

  return defined ($self->db->selectrow_hashref(
    "SELECT Email FROM Users WHERE Email = ?",
    {},
    $email,
  ));
};

helper set_token_as_used => sub {
  my ( $self, $token ) = @_;

  #Return true if and only if the token exists and has not been used.
  my $statement = $self->db->prepare("UPDATE Tokens SET Used = 1 WHERE TokenName = ? AND Used = 0 ");
  my $rows = $statement->execute($token);

  #print '-set_token_as_used-'.(Dumper($rows))."-\n";

  return $rows != 0;
};

helper generate_hashed_password => sub {
  my ( $self, $password) = @_;

  my $ppr = Authen::Passphrase::BlowfishCrypt->new(
    cost => 8, salt_random => 1,
    passphrase => $password);
  return $ppr->as_crypt;

};
 
# We assume the user already exists.
helper check_password_email => sub{
  my ( $self, $email, $password) = @_;

  my $statement = $self->db->prepare("SELECT HashedPassword FROM Users WHERE Email = ?");
  my $result -> execute($email);
  my ($hashedPassword) = $result->fetchrow_array;

  my $ppr = Authen::Passphrase::BlowfishCrypt->from_crypt($hashedPassword);

  return $ppr->match($password);
};

app->start;
