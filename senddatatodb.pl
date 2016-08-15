#!/usr/bin/env perl

use Mojolicious::Lite;
use Data::UUID;

# connect to database
use DBI;
my $config = plugin Config => {file => 'myapp.conf'};

use Devel::Dwarn; Dwarn $config;

my $dbh = DBI->connect($config->{dsn}) or die "Could not connect";

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
  # Fetch parameters to write to DB
  my $user = $self->param('user');
  my $company = $self->param('company');
  my $currency = $self->param('currency');
  my $file = $self->req->upload('file');
  # Get image type and check extension
  my $headers = $file->headers->content_type;
  # Is content type wrong?
  if ($headers ne 'image/jpeg') {
      print "Upload fail. Content type is wrong.\n";
  };
  # Rewrite header data
  my $ext = '.jpg';
  my $uuid = Data::UUID->new->create_str;
  my $filename = $uuid . $ext;
  $file->move_to('images/' . $filename);
  $insert->execute($user, $company, $currency, $filename);
  $self->render(text => 'It did not kaboom!');
};

app->start;
