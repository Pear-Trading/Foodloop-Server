use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

my $user = $schema->resultset('User')->create({
  email => 'admin@example.com',
  password => 'abc123',
  administrator => {},
});

is $schema->resultset('Administrator')->count, 1, 'Admin Created';

my $user1 = {
  token        => 'a',
  full_name    => 'Test User1',
  display_name => 'Test User1',
  email        => 'test1@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $org = {
  token       => 'e',
  email       => 'test50@example.com',
  name        => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town        => 'Midgar',
  postcode    => 'WC1E 6AD',
  password    => 'abc123',
};

$schema->resultset('AccountToken')->create({ name => $_->{token} })
  for ( $user1, $org );

$framework->register_customer($user1);

$framework->register_organisation($org);

#login to admin
$t->ua->max_redirects(10);
$t->post_ok('/admin', form => {
  email => 'admin@example.com',
  password => 'abc123',
})->status_is(200);

#Read customer user
$t->get_ok('/admin/users/1/')
  ->status_is(200);

#Read organisation user
$t->get_ok('/admin/users/2/')
  ->status_is(200);

#Valid organisation user update
$t->post_ok('/admin/users/1/edit', form => {
  email => 'test51@example.com',
  new_password => 'abc123',
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
  postcode => 'WC1E 6AD',
})->status_is(200)->content_like(qr/Updated User/);

#Failed validation on organisation user from wrong email
$t->post_ok('/admin/users/1/edit', form => {
  email => 'test55@example.com',
  new_password => 'abc123',
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
  postcode => 'WC1E 6AD',
})->content_like(qr/The validation has failed/);

#Failed validation on organisation user from no postcode
$t->post_ok('/admin/users/1/edit', form => {
  email => 'test50@example.com',
  new_password => 'abc123',
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
})->content_like(qr/The validation has failed/);

#Failed validation on organisation user from no street name
$t->post_ok('/admin/users/1/edit', form => {
  email => 'test50@example.com',
  new_password => 'abc123',
  name => '7th Heaven',
  town => 'Midgar',
  postcode => 'WC1E 6AD',
})->content_like(qr/The validation has failed/);

done_testing();
