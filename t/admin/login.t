use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;

my $location_is = sub {
  my ($t, $value, $desc) = @_;
  $desc ||= "Location: $value";
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return $t->success(is($t->tx->res->headers->location, $value, $desc));
};

$t->get_ok('/admin')
  ->status_is(200)->or($framework->dump_error);

$t->ua->max_redirects(10);
$t->post_ok('/admin', form => {
  email => 'test1@example.com',
  password => 'abc123',
})->status_is(200);

$t->ua->max_redirects(0);
$t->get_ok('/admin')
  ->status_is(200);

$t->get_ok('/admin/logout')
  ->status_is(302)
  ->$location_is('/admin');

$t->get_ok('/admin')
  ->status_is(200);

$t->ua->max_redirects(10);
$t->post_ok('/admin', form => {
  email => 'admin@example.com',
  password => 'abc123',
})->status_is(200);

$t->ua->max_redirects(0);
$t->get_ok('/admin/home')
  ->status_is(200)
  ->content_like(qr/Admin/);

$t->get_ok('/admin/logout')
  ->status_is(302)
  ->$location_is('/admin');

$t->get_ok('/admin')
  ->status_is(200);

done_testing;

