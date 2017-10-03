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

$t->post_ok('/api/user', json => { session_key => $session_key })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    full_name => 'Test User',
    display_name => 'Testing User',
    email => $email,
    postcode => 'LA1 1AA',
    location => {
      latitude => undef,
      longitude => undef,
    },
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
    location => {
      latitude => undef,
      longitude => undef,
    },

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
    location => {
      latitude => undef,
      longitude => undef,
    },

  });

$session_key = $framework->login({
  email => 'test60@example.com',
  password => 'abc124',
});

done_testing;
