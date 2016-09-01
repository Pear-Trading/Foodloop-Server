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

# setup base route
#any '/' => 'index';

my $insert;
while (1) {
  print "Checking if table exists";
  # create insert statement
  $insert = eval { $dbh->prepare('UPDATE accounts SET 'name' = ?, email = ?, postcode = ?, age = ?, gender = ?, grouping = ?, password = ?, keyused = ? WHERE username = ?');
  # break out of loop if statement prepared
  last if $insert;
  print "Make the table!";
}

post '/' => sub {
  my $self = shift;
# get the key from user
  my $key = $self->req->json;
# Check if that token key has been used before
  my $keyused = $dbh->selectall_arrayref("SELECT keyused FROM accounts WHERE idkey = ?", undef, $key->{token});
# if the key has been used before, tell the user to sod off
  unless ($keyused != t) {
  print "The key $key has already been used!";
  return $self->render(json => {'success' => Mojo::JSON->false});
}
# get from db the username matching the key and then send it back at them
  my $username = $dbh->selectall_arrayref("SELECT username FROM accounts WHERE idkey = ?", undef, $key->{token});
  $self->render(json => {'username' => $username->[0], success => Mojo::JSON->true}  );
# When user has submitted json of data, define data
  my $name = $self->req->json;
  my $email = $self->req->json;
  my $postcode = $self->req->json;
  my $age = $self->req->json;
  my $gender = $self->req->json;
  my $grouping = $self->req->json;
  my $password = $self->req->json;
  my $keyused = "True";
# send data to db in row matching username
  $insert->execute($name->{name}, $email->{email}, $postcode->{postcode}, $age->{age}, $gender->{gender}, $grouping->{grouping}, $password->{password}, $keyused, $username);
  $self->render(text => 'It did not kaboom!');
};

app->start;
