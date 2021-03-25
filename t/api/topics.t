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
  email => 'org@example.com',
  password => 'abc123',
});

## Topics

#No JSON sent
$t->post_ok('/api/topic/add')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/topic/add' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false);
  
#No session key
$t->post_ok('/api/topic/add' => json => {
    topic => 'test',
  })
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Invalid Session/);
  
#Create new topic
$t->post_ok('/api/topic/add' => json => {
    session_key => $session_key,
    topic => 'test',
	})
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

#No JSON sent
$t->post_ok('/api/topics')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/topics' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false);
  
#Get all topics
$t->post_ok('/api/topics' => json => {
    session_key => $session_key
	})
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);
  
#No JSON sent
$t->post_ok('/api/topics/subscriptions')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/topics/subscriptions' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false);
  
#Get all subscriptions
$t->post_ok('/api/topics/subscriptions' => json => {
    session_key => $session_key,
	})
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);
  
#No JSON sent
$t->post_ok('/api/topics/update')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/topics/update' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false);
  
#No session key
$t->post_ok('/api/topics/update' => json => {
    topicSubscriptions => [
    	{
    		id => 1,
    		name => 'test',
    		isSubscribed => Mojo::JSON->true,
    	}
    ],
  })
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Invalid Session/);
  
#Create new topic
$t->post_ok('/api/topics/update' => json => {
    session_key => $session_key,
    topicSubscriptions => [
    	{
    		id => 1,
    		name => 'test',
    		isSubscribed => Mojo::JSON->true,
    	}
    ],
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);
  
    
$framework->logout( $session_key );

done_testing;
