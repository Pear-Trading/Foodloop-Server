use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib "$Bin/../../lib";

use File::Temp;
use Test::More;
use Test::Mojo;
use DateTime;
my $file = File::Temp->new;

print $file <<'END';
{
  dsn => "dbi:SQLite::memory:",
  user => undef,
  pass => undef,
}
END
$file->seek( 0, SEEK_END );

$ENV{MOJO_CONFIG} = $file->filename;

my $t = Test::Mojo->new('Pear::LocalLoop');
my $schema = $t->app->schema;
$schema->deploy;

$schema->resultset('User')->create({
  email => 'admin@example.com',
  password => 'abc123',
  administrator => {},
});

$schema->resultset('User')->create({
  email => 'user@example.com',
  password => 'abc123',
});

is $schema->resultset('User')->count, 2, 'Users Created';
is $schema->resultset('Administrator')->count, 1, 'Admin Created';

my $location_is = sub {
  my ($t, $value, $desc) = @_;
  $desc ||= "Location: $value";
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return $t->success(is($t->tx->res->headers->location, $value, $desc));
};

$t->get_ok('/admin')
  ->status_is(302)
  ->$location_is('/');

$t->ua->max_redirects(10);
$t->post_ok('/', form => {
  email => 'user@example.com',
  password => 'abc123',
})->status_is(200);

$t->ua->max_redirects(0);
$t->get_ok('/admin')
  ->status_is(302)
  ->$location_is('/home');

$t->get_ok('/logout')
  ->status_is(302)
  ->$location_is('/');

$t->get_ok('/admin')
  ->status_is(302)
  ->$location_is('/', 'Logged out');

$t->ua->max_redirects(10);
$t->post_ok('/', form => {
  email => 'admin@example.com',
  password => 'abc123',
})->status_is(200);

$t->ua->max_redirects(0);
$t->get_ok('/admin')
  ->status_is(200)
  ->content_like(qr/Admin/);

$t->get_ok('/logout')
  ->status_is(302)
  ->$location_is('/');

$t->get_ok('/admin')
  ->status_is(302)
  ->$location_is('/', 'Logged out');

done_testing;

