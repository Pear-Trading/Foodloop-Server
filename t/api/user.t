use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

my $account_token = 'a';
my $email = 'test@example.com';
my $password = 'abc123';

$schema->resultset('AccountToken')->create({
  name => $account_token
});

$framework->register_customer({
  'token' => $account_token,
  'full_name' =>  'Test User',
  'display_name' =>  'Testing User',
  'email' => $email,
  'postcode' => 'LA1 1AA',
  'password' => $password,
  year_of_birth => 2006
});

my $session_key = $framework->login({
  email => $email,
  password => $password,
});

my $json_no_date = { session_key => $session_key };
$t->post_ok('/api/user/day', json => $json_no_date)
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

my $json_invalid_date = {
  session_key => $session_key,
  day => 'invalid',
};
$t->post_ok('/api/user/day', json => $json_invalid_date)
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Invalid ISO8601 Datetime/);

my $json_valid_date = {
  session_key => $session_key,
  day => $t->app->datetime_formatter->format_datetime(DateTime->now),
};
$t->post_ok('/api/user/day', json => $json_valid_date)
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    full_name => 'Test User',
    display_name => 'Testing User',
    email => $email,
    postcode => 'LA1 1AA',
  });

#with wrong password
$t->post_ok('/api/user/account', json => {
  session_key => $session_key,
  full_name => 'Test User 2',
  display_name => 'Testing User 2',
  email => 'test50@example.com',
  postcode => 'LA1 1AB',
  password => 'abc12431',
  })
  ->status_is(401)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->false,
    message => 'password is invalid.',
  });

# With valid details
$t->post_ok('/api/user/account', json => {
  session_key => $session_key,
  full_name => 'Test User 2',
  display_name => 'Testing User 2',
  email => 'test50@example.com',
  postcode => 'LA1 1AB',
  password => $password,
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    message => 'Edited Account Successfully',
  });

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    full_name => 'Test User 2',
    display_name => 'Testing User 2',
    email => 'test50@example.com',
    postcode => 'LA1 1AB',
  });

$t->post_ok('/api/user/account', json => {
  session_key => $session_key,
  full_name => 'Test User 3',
  display_name => 'Testing User 3',
  email => 'test60@example.com',
  postcode => 'LA1 1AD',
  password => $password,
  new_password => 'abc124',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    message => 'Edited Account Successfully',
  });

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    full_name => 'Test User 3',
    display_name => 'Testing User 3',
    email => 'test60@example.com',
    postcode => 'LA1 1AD',
  });

$session_key = $framework->login({
  email => 'test60@example.com',
  password => 'abc124',
});

done_testing;
