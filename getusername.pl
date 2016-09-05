#!/usr/bin/env perl
# NOT READY FOR PRODUCTION

use Mojolicious::Lite;
use Data::UUID;
use Devel::Dwarn;
use Mojo::JSON;

# connect to database
use DBI;

my $config = plugin Config => {file => 'myapp.conf'};
my $dbh = DBI->connect($config->{dsn},$config->{user},$config->{pass}) or die "Could not connect";
Dwarn $config;

# shortcut for use in template
helper db => sub { $dbh };

any '/' => sub {
  my $self = shift;

  $self->render(text => 'It did not kaboom!');
};

post '/upload' => sub {
  my $self = shift;
# Fetch parameters to write to DB
#  my $key = $self->param('key');
# This will include an if function to see if key matches
#  unless ($key eq $config->{key}) {
#    return $self->render( json => { success => Mojo::JSON->false }, status => 403 );
#  } 
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
  $self->render(text => 'It did not kaboom!');

};

post '/register' => sub {
  my $self = shift;

  my $json = $self->req->json;

  my $account = $self->get_account_by_username( $json->{username} );

  unless ( defined $account ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username not recognised, has your token expired?',
    });
  } elsif ( $account->{keyused} eq 't' ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token has already been used',
    });
  }
  my $insert = $self->db->prepare("UPDATE accounts SET 'name' = ?, email = ?, postcode = ?, age = ?, gender = ?, grouping = ?, password = ?, keyused = ? WHERE username = ?");
  $insert->execute(
    @{$json}{ qw/ name email postcode age gender grouping password / }, 'True', $account->{username},
  );

  $self->render( json => { success => Mojo::JSON->true } );
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
  my $insert = $self->db->prepare("UPDATE accounts SET 'name' = ?, postcode = ?, age = ?, gender = ?, WHERE username = ?");
  $insert->execute(
    @{$json}{ qw/ name postcode age gender / }, $account->{username},
  );

  $self->render( json => { success => Mojo::JSON->true } );
};


post '/token' => sub {
  my $self = shift;

  my $json = $self->req->json;

  my $account = $self->get_account_by_token( $json->{token} );

  # TODO change to proper boolean checks
  if ( ! defined $account || $account->{keyused} eq 't' ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token is invalid or has already been used',
    });
  }
  return $self->render( json => {
    username => $account->{username},
    success => Mojo::JSON->true,
  });
};

sub get_account_by_token {
  my ( $self, $token ) = @_;

  return $self->db->selectrow_hashref(
    'SELECT keyused, username FROM accounts WHERE idkey = ?',
    {},
    $token,
  );
}

sub get_account_by_username {
  my ( $self, $username ) = @_;

  return $self->db->selectrow_hashref(
    'SELECT keyused, username FROM accounts WHERE username = ?',
    {},
    $username,
  );
}

app->start;
