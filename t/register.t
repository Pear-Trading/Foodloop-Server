use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

#Variables to be used for uniqueness when testing.
my @names = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');
my @emails = ('a@a.com', 'b@a.com', 'c@a.com', 'd@a.com', 'e@a.com', 'f@a.com', 'g@a.com', 'h@a.com', 'i@a.com', 'j@a.com', 'k@a.com', 'l@a.com', 'm@a.com', 'n@a.com', 'o@a.com', 'p@a.com', 'q@a.com', 'r@a.com', 's@a.com', 't@a.com', 'u@a.com', 'v@a.com', 'w@a.com', 'x@a.com', 'y@a.com', 'z@a.com');
my @tokens =  ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');

$schema->resultset('AccountToken')->populate([
  [ qw/ accounttokenname / ],
  map { [ $_ ] } @tokens,
]);

#No JSON sent
$t->post_ok('/api/register')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no json sent/i);

#Empty JSON
my $testJson = {};
$t->post_ok('/api/register' => json => $testJson)
  ->json_is('/success', Mojo::JSON->false);

#token missing JSON
$testJson = {
  'usertype' => 'customer',
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no token sent/i);


#Not valid token.
$testJson = {
  'usertype' => 'customer',
  'token' => ' ',
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/token/i)
  ->content_like(qr/invalid/i);

#username missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no username sent/i);


#Blank username
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens), 
  'username' => '', 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/blank/i)
  ->content_like(qr/username/i);

#Not alpha numeric chars e.g. !
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens), 
  'username' =>  'asa!', 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/username/i);

my $usernameToReuse =  shift(@names);
my $emailToReuse =  shift(@emails);

#Valid customer
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  $usernameToReuse, 
  'email' => $emailToReuse, 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#Valid customer2
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);

#Valid customer3
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '20-35'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);

#Username exists
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' => $usernameToReuse, 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(403) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/exists/i);

#email missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no email sent/i);

#invalid email 1 
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => 'dfsd@.com', 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/invalid/i);

#invalid email 2
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => 'dfsd@com', 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/invalid/i);

#Email exists
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => $emailToReuse, 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(403) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/exists/i);

#postcode missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no postcode sent/i);

#TODO validate postcode

#password missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no password sent/i);

#TODO enforce password complexity requirements.

#usertype missing JSON
$testJson = {
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no usertype sent/i);

#Invalid user type
$testJson = {
  'usertype' => 'organisation1', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'fulladdress' => 'mary lane testing....'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/usertype/i)
  ->content_like(qr/invalid/i);


#age missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no age sent/i);

#Age is invalid
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => 'invalid'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/age/i)
  ->content_like(qr/invalid/i);

#full address missing JSON
$testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no fulladdress sent/i);

#TODO Validation of full address

#Organisation valid
$testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'fulladdress' => 'mary lane testing....'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);

is $t->app->schema->resultset('User')->count, 4, 'Correct user count';
is $t->app->schema->resultset('Customer')->count, 3, 'Correct customer count';
is $t->app->schema->resultset('Organisation')->count, 1, 'Correct organisation count';

done_testing();
