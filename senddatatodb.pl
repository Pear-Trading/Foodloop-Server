#!/usr/bin/env perl

use Mojolicious::Lite;

# connect to database
use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=foodloop.db") or die "Could not connect";

# shortcut for use in template
helper db => sub { $dbh }; 

# setup base route
#any '/' => 'index';

my $insert;
while (1) {
  # create insert statement
  $insert = eval { $dbh->prepare('INSERT INTO foodloop (user, company, currency, filename) VALUES (?,?,?,?)') };
  # break out of loop if statement prepared
  last if $insert;

  # if statement didn't prepare, assume its because the table doesn't exist
  warn "Creating table 'foodloop'\n";
  $dbh->do('CREATE TABLE foodloop (user varchar(255), company varchar(255), currency int, filename varchar(255));');
}

# setup route which receives data and returns to /
post '/' => sub {
  my $self = shift;
  my $user = $self->param('user');
  my $company = $self->param('company');
  my $currency = $self->param('currency');
  my $file = $self->req->upload('file');
  $insert->execute($user, $company, $currency, $file->filename);
  $self->render(text => 'It did not kaboom!');
};

app->start;
