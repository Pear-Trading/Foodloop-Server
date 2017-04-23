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
  'name' =>  'Test User',
  'email' => $email,
  'postcode' => 'LA1 1AA',
  'password' => $password,
  'age_range' => 1
});

my $session_key = $framework->login({
  email => $email,
  password => $password,
});

my $json_no_date = { session_key => $session_key };
$t->post_ok('/api/user/day', json => $json_no_date)
  ->status_is(200)
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

done_testing;
