use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

my $user = {
  token         => 'a',
  usertype      => 'customer',
  display_name  => 'Display Guy',
  full_name     => 'Real Name',
  email         => 'test@example.com',
  postcode      => 'LA1 1AA',
  password      => 'testerising',
  year_of_birth => 2006,
};

$schema->resultset('AccountToken')->create({ name => $user->{token} });

$t->post_ok('/api/register' => json => $user)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

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
    email => $user->{email},
    password => $user->{password},
  })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/display_name', 'Display Guy')
  ->json_is('/user_type', 'customer')
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
