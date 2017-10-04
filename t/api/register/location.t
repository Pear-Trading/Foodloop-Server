use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../../etc",
);
$framework->install_fixtures('full');

my $t = $framework->framework;
my $schema = $t->app->schema;

$schema->resultset('AccountToken')->populate([
  {name => 'test1'},
  {name => 'test2'},
  {name => 'test3'},
]);

$t->post_ok('/api/register',
  json => {
    token => 'test1',
    usertype => 'customer',
    full_name => 'New Test User',
    display_name => 'Testing User New',
    email => 'newtest@example.com',
    postcode => 'LA2 0AD',
    year_of_birth => 2001,
    password => 'abc123',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

my $session_key = $framework->login({
  email => 'newtest@example.com',
  password => 'abc123',
});

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/location', {
      latitude => 54.02,
      longitude => -2.80,
    }
  );

$t->post_ok('/api/register',
  json => {
    token => 'test2',
    usertype => 'organisation',
    email => 'neworg@example.com',
    password => 'abc123',
    postcode => 'LA2 0AD',
    name => 'New Org',
    street_name => '18 Test Road',
    town => 'Lancaster',
    sector => 'A',
  })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

$session_key = $framework->login({
  email => 'neworg@example.com',
  password => 'abc123',
});

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/location', {
       latitude  => 54.02432,
       longitude => -2.80635,
    }
  );

$t->post_ok('/api/register',
  json => {
    token => 'test3',
    usertype => 'customer',
    full_name => 'New Test User',
    display_name => 'Testing User New',
    email => 'newtest2@example.com',
    postcode => 'BX1 1AA',
    year_of_birth => 2001,
    password => 'abc123',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

$session_key = $framework->login({
  email => 'newtest2@example.com',
  password => 'abc123',
});

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/location', {
      latitude => undef,
      longitude => undef,
    }
  );

done_testing;
