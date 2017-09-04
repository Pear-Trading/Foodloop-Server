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

#login to admin
$t->ua->max_redirects(10);
$t->post_ok('/admin', form => {
  email => 'admin@example.com',
  password => 'abc123',
})->status_is(200);

$t->get_ok('/admin/users')
  ->status_is(200)
  ->or($framework->dump_error);

#Read customer user
$t->get_ok('/admin/users/1')
  ->status_is(200);

#Read organisation user
$t->get_ok('/admin/users/5')
  ->status_is(200);

#Valid customer user update
$t->post_ok(
  '/admin/users/1',
  form => {
    email => 'test12@example.com',
    new_password => 'abc123',
    full_name => 'Test User1',
    display_name => 'Test User1',
    town => 'Midgar',
    sector => 'A',
    postcode => 'WC1E 6AD',
  })
  ->status_is(200)
  ->or($framework->dump_error)
  ->content_like(qr/Updated User/);

#Failed validation on customer user from no postcode
$t->post_ok('/admin/users/2', form => {
  email => 'test12@example.com',
  new_password => 'abc123',
  full_name => 'Test User1',
  display_name => 'Test User1',
  town => 'Midgar',
  sector => 'A',
})->content_like(qr/The validation has failed/);

#Failed validation on customer user from no display name
$t->post_ok('/admin/users/2', form => {
  email => 'test12@example.com',
  new_password => 'abc123',
  full_name => 'Test User1',
  town => 'Midgar',
  postcode => 'WC1E 6AD',
  sector => 'A',
})->content_like(qr/The validation has failed/);

#Valid organisation user update
$t->post_ok('/admin/users/5', form => {
  email => 'test51@example.com',
  new_password => 'abc123',
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
  sector => 'A',
  postcode => 'WC1E 6AD',
})->status_is(200)->content_like(qr/Updated User/);

#Failed validation on organisation user from no postcode
$t->post_ok('/admin/users/5', form => {
  email => 'test50@example.com',
  new_password => 'abc123',
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
  sector => 'A',
})->content_like(qr/The validation has failed/);

#Failed validation on organisation user from no street name
$t->post_ok('/admin/users/5', form => {
  email => 'test50@example.com',
  new_password => 'abc123',
  name => '7th Heaven',
  town => 'Midgar',
  sector => 'A',
  postcode => 'WC1E 6AD',
})->content_like(qr/The validation has failed/);

done_testing();
