use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

my $account_token = 'a';
my $email = 'rufus@shinra.energy';
my $password = 'MakoGold';

$schema->resultset('AccountToken')->create({
  name => $account_token
});

my $test_json = {
  'usertype' => 'customer', 
  'token' => $account_token, 
  'display_name' =>  'RufusShinra', 
  'full_name' =>  'RufusShinra', 
  'email' => $email, 
  'postcode' => 'LA1 1AA', 
  'password' => $password, 
  'age_range' => 1
};
$t->post_ok('/api/register' => json => $test_json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
use Data::Dumper;

is $schema->resultset('User')->count, 1, 'found a user';

$t->post_ok('/api' => json => {
    session_key => 'invalid',
  })
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Invalid Session/);

$t->post_ok('/api/login' => json => {
    email => 'nonexistant@test.com',
    password => 'doesnt matter',
  })
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false);

$t->post_ok('/api/login' => json => {
    email => $email,
    password => $password,
  })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/session_key');

my $session_key = $t->tx->res->json->{session_key};

$t->post_ok('/api' => json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Successful Auth/);

is $schema->resultset('SessionToken')->count, 1, 'One Session';

$t->post_ok('/api/logout' => json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Logged Out/);

is $schema->resultset('SessionToken')->count, 0, 'No Sessions';

done_testing;
