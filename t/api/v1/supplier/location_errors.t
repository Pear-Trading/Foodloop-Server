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

$t->post_ok('/api/v1/supplier/location' => json => {
    session_key => $session_key,
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/errors', [
    'required_north_east',
    'required_south_west',
  ]);

$t->post_ok('/api/v1/supplier/location' => json => {
    session_key => $session_key,
    north_east => 'banana',
    south_west => 'apple',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/errors', [
    'not_object_north_east',
    'not_object_south_west',
  ]);

$t->post_ok('/api/v1/supplier/location' => json => {
    session_key => $session_key,
    north_east => {},
    south_west => {},
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/errors', [
    'required_north_east_latitude',
    'required_north_east_longitude',
    'required_south_west_latitude',
    'required_south_west_longitude',
  ]);

$t->post_ok('/api/v1/supplier/location' => json => {
    session_key => $session_key,
    north_east => {
      latitude => 'banana',
      longitude => 'apple',
    },
    south_west => {
      latitude => 'grapefruit',
      longitude => 'orange',
    },
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/errors', [
    'not_number_north_east_latitude',
    'not_number_north_east_longitude',
    'not_number_south_west_latitude',
    'not_number_south_west_longitude',
  ]);

$t->post_ok('/api/v1/supplier/location' => json => {
    session_key => $session_key,
    north_east => {
      latitude => 90.00001,
      longitude => 180.00001,
    },
    south_west => {
      latitude => -90.00001,
      longitude => -180.00001,
    },
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/errors', [
    'outside_range_north_east_latitude',
    'outside_range_north_east_longitude',
    'outside_range_south_west_latitude',
    'outside_range_south_west_longitude',
  ]);

# upside down when NeLat < SwLat
$t->post_ok('/api/v1/supplier/location' => json => {
    session_key => $session_key,
    north_east => {
      latitude => -89,
      longitude => 170,
    },
    south_west => {
      latitude => 89,
      longitude => -170,
    },
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/errors', [
    'upside_down',
  ])->or($framework->dump_error);

done_testing;
