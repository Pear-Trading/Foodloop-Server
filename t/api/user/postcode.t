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

my $session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/postcode', 'LA1 1AA')
  ->json_is('/location', {
      latitude => 54.04,
      longitude => -2.80,
    }
  );

$t->post_ok('/api/user/account', json => {
  session_key => $session_key,
  full_name => 'Test User1',
  display_name => 'Testing User1',
  email => 'test1@example.com',
  postcode => 'LA2 0AR',
  password => 'abc123',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/postcode', 'LA2 0AR')
  ->json_is('/location', {
      latitude => 53.99,
      longitude => -2.84,
    }
  );

done_testing;
