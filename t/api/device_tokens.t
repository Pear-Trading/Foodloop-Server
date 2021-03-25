use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;

my $session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

my $token = 'd-ukAXXVWudTtDg1q2kHY6:APA91bEfTE3VGB0EjDuVA0QX5XMTrQU4szYWv64LpV9_VUD4zfL7SKEKLd0gnm0yPPPcWaol-PcADVkfXQCmQKLMhVnqTSVs1MzGv0j_6bpWb0Rrqnv63umFbv99jZV8rEgIfSjsbMki';

## Device Tokens

#No JSON sent
$t->post_ok('/api/device-token/check')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/device-token/check' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false);

#No session key
$t->post_ok('/api/device-token/check' => json => {
    token => $token
  })
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Invalid Session/);
  
#Non-existent token
$t->post_ok('/api/device-token/check' => json => {
    session_key => $session_key,
    token => $token
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/exists', Mojo::JSON->false);

#TODO: add a check for a real token

#No JSON sent
$t->post_ok('/api/device-token/add')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/device-token/add' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false);
  
#No session key
$t->post_ok('/api/device-token/add' => json => {
    token => $token,
		email => 'test@test.com'
  })
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Invalid Session/);
  
#Non-existent token
$t->post_ok('/api/device-token/add' => json => {
    session_key => $session_key,
		token => $token,
		email => 'test1@example.com'
	})
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);
  
#TODO: add a check for a real token

#No JSON sent
$t->post_ok('/api/device-tokens')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/device-tokens' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false);
  
#Non-existent token
$t->post_ok('/api/device-tokens' => json => {
    session_key => $session_key,
	})
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);
  
#TODO: add a check for a real token

$framework->logout( $session_key );

done_testing;
