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

my $valid_entity = $schema->resultset('Entity')->create({
  organisation => {
    name => 'Shinra Electric Power Company',
    street_name => 'Sector 0, Midgar, Eastern Continent',
    town => 'Gaia',
    sector => 'A',
    postcode => 'WC1E 6AD',
  },
  type => "organisation",
});

my $pending_entity = $schema->resultset('Entity')->create({
  organisation => {
    name => '7th Heaven',
    street_name => 'Slums, Sector 7',
    town => 'Midgar',
    sector => 'A',
    postcode => 'WC1E 6AD',
    pending => \"1",
  },
  type => "organisation",
});

my $valid_id = $valid_entity->organisation->id;
my $pending_id = $pending_entity->organisation->id;

#login to admin
$t->ua->max_redirects(10);
$t->post_ok('/admin', form => {
  email => 'admin@example.com',
  password => 'abc123',
})->status_is(200);

#Read approved organisation
$t->get_ok("/admin/organisations/$valid_id")
  ->status_is(200)->or($framework->dump_error);

#Read pending organisation
$t->get_ok("/admin/organisations/$pending_id")
  ->status_is(200)->or($framework->dump_error);

#Valid approved organisation update
$t->post_ok("/admin/organisations/$valid_id", form => {
  name => 'Shinra Electric Power Company',
  street_name => 'Sector 0, Midgar, Eastern Continent',
  town => 'Gaia',
  sector => 'A',
  postcode => 'WC1E 6AD',
})->status_is(200)->content_like(qr/Updated Organisation/);

#Failed validation on approved organisation
$t->post_ok("/admin/organisations/$valid_id", form => {
  name => 'Shinra Electric Power Company',
  street_name => 'Sector 0, Midgar, Eastern Continent',
  sector => 'A',
  postcode => 'WC1E 6AD',
})->content_like(qr/The validation has failed/);

#Valid pending organisation update
$t->post_ok("/admin/organisations/$pending_id", form => {
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  town => 'Midgar',
  postcode => 'WC1E 6AD',
})->status_is(200)->content_like(qr/Updated Organisation/);

#Failed validation on pending organisation
$t->post_ok("/admin/organisations/$pending_id", form => {
  name => '7th Heaven',
  street_name => 'Slums, Sector 7',
  postcode => 'WC1E 6AD',
})->content_like(qr/The validation has failed/);

#Valid adding organisation
$t->post_ok('/admin/organisations/add', form => {
  name => 'Wall Market',
  street_name => 'Slums, Sector 6',
  town => 'Midgar',
  sector => 'A',
  postcode => 'TN35 5AQ',
})->status_is(200)->content_like(qr/Added Organisation/);

#Failed validation on adding organisation
$t->post_ok('/admin/organisations/add', form => {
  name => 'Wall Market',
  street_name => 'Slums, Sector 6',
  postcode => 'TN35 5AQ',
})->content_like(qr/The validation has failed/);

done_testing();
