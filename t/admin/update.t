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

$schema->resultset('Organisation')->create({
  id => 1,
  name => 'Shinra Electric Power Company',
  street_name => 'Sector 0, Midgar, Eastern Continent',
  town => 'Gaia',
  postcode => 'WC1E 6AD',
});

$schema->resultset('PendingOrganisation')->create({
  id => 2,
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
  postcode => 'WC1E 6AD',
  submitted_by_id => $user->id,
});

#login to admin
$t->ua->max_redirects(10);
$t->post_ok('/admin', form => {
  email => 'admin@example.com',
  password => 'abc123',
})->status_is(200);

#Read approved organisation
$t->get_ok('/admin/organisations/valid/1/')
  ->status_is(200);

#Read pending organisation
$t->get_ok('/admin/organisations/pending/2/')
  ->status_is(200);

#Valid approved organisation update
$t->post_ok('/admin/organisations/valid/1/edit', form => {
  name => 'Shinra Electric Power Company',
  street_name => 'Sector 0, Midgar, Eastern Continent',
  town => 'Gaia',
  postcode => 'WC1E 6AD',
})->status_is(200)->content_like(qr/Updated Organisation/);

#Failed validation on approved organisation
$t->post_ok('/admin/organisations/valid/1/edit', form => {
  name => 'Shinra Electric Power Company',
  street_name => 'Sector 0, Midgar, Eastern Continent',
  postcode => 'WC1E 6AD',
})->content_like(qr/The validation has failed/);

#Valid pending organisation update
$t->post_ok('/admin/organisations/pending/2/edit', form => {
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
  postcode => 'WC1E 6AD',
})->status_is(200)->content_like(qr/Updated Organisation/);

#Failed validation on pending organisation
$t->post_ok('/admin/organisations/pending/2/edit', form => {
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  postcode => 'WC1E 6AD',
})->content_like(qr/The validation has failed/);

done_testing();
