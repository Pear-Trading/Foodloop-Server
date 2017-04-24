use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

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
  ->status_is(200)->or($framework->dump_error);

$t->ua->max_redirects(10);
$t->post_ok('/admin', form => {
  email => 'user@example.com',
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

