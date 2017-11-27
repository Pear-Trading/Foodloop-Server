use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../../../etc",
);
$framework->install_fixtures('full');

my $t = $framework->framework;
my $schema = $t->app->schema;

my $session_key = $framework->login({
  email => 'org1@example.com',
  password => 'abc123',
});

$t->post_ok('/api/upload' => json => {
    transaction_value => 10,
    transaction_type => 1,
    purchase_time => "2017-08-14T11:29:07.965+01:00",
    organisation_id => 2,
    session_key => $session_key,
  })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

# Rough area around Lancaster
$t->post_ok('/api/v1/supplier/location' => json => {
    session_key => $session_key,
    north_east => {
      latitude => 54.077665,
      longitude => -2.761860,
    },
    south_west => {
      latitude => 54.013361,
      longitude => -2.857647,
    },
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/suppliers', [
    {
      name => 'Test Org 2',
      latitude => 54.04679,
      longitude => -2.7963,
      street_name => 'Test Street',
      town => 'Lancaster',
      postcode => 'LA1 1AG',
    },
  ])
  ->json_is('/self', {
      latitude => 54.04725,
      longitude => -2.79611,
  });

  $t->post_ok('/api/v1/supplier/location/lis' => json => {
      session_key => $session_key,
      north_east => {
        latitude => 54.077665,
        longitude => -2.761860,
      },
      south_west => {
        latitude => 54.013361,
        longitude => -2.857647,
      },
    })
    ->status_is(200)->or($framework->dump_error)
    ->json_is('/success', Mojo::JSON->true)
    ->json_is('/locations', [
      {
        name => 'Test Org 2',
        latitude => 54.04679,
        longitude => -2.7963,
        street_name => 'Test Street',
        town => 'Lancaster',
        postcode => 'LA1 1AG',
      },
    ])
    ->json_is('/self', {
        latitude => 54.04725,
        longitude => -2.79611,
    });

done_testing;
