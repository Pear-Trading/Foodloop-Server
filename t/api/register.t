use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;
my $dump_error = $framework->dump_error;

#Variables to be used for uniqueness when testing.
my @tokens =  ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');

$schema->resultset('AccountToken')->populate([
  [ qw/ name / ],
  map { [ $_ ] } @tokens,
]);

#No JSON sent
$t->post_ok('/api/register')
  ->status_is(400)->or($dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
my $testJson = {};
$t->post_ok('/api/register' => json => $testJson)
  ->json_is('/success', Mojo::JSON->false);

#token missing JSON
$testJson = {
  'usertype' => 'customer',
  'full_name' => 'test name',
  'display_name' => 'test name',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no token sent/i);

#Not valid token.
$testJson = {
  'usertype' => 'customer',
  'token' => 'testing',
  'display_name' => 'test name',
  'full_name' => 'test name',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/token/i)
  ->content_like(qr/invalid/i);

#name missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => 'a',
  'full_name' => 'test name',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no display name sent/i);
#name missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => 'a',
  'display_name' => 'test name',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no full name sent/i);

#Blank name
$testJson = {
  'usertype' => 'customer',
  'token' => 'a',
  'display_name' => 'test name',
  'full_name' => '',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/blank/i)
  ->content_like(qr/name/i);
#Blank name
$testJson = {
  'usertype' => 'customer',
  'token' => 'a',
  'display_name' => '',
  'full_name' => 'test name',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/blank/i)
  ->content_like(qr/name/i);


#Valid customer
$testJson = {
  'usertype' => 'customer',
  'token' => 'a',
  'full_name' =>  'test name',
  'display_name' =>  'test name',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#Valid customer2
$testJson = {
  'usertype' => 'customer',
  'token' => 'b',
  'full_name' =>  'test name',
  'display_name' =>  'test name',
  'email' => 'b@c.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->or($dump_error)
  ->status_is(200)
  ->or($dump_error)
  ->json_is('/success', Mojo::JSON->true)
  ->or($dump_error);

#Valid customer3
$testJson = {
  'usertype' => 'customer',
  'token' => 'c',
  'full_name' => 'test name',
  'display_name' => 'test name',
  'email' => 'c@d.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#email missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => 'd',
  'full_name' => 'test name',
  'display_name' => 'test name',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2005
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no email sent/i);

#invalid email 1
$testJson = {
  'usertype' => 'customer',
  'token' => 'd',
  'full_name' =>  'test name',
  'display_name' =>  'test name',
  'email' => 'dfsd@.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2006
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/invalid/i);

#invalid email 2
$testJson = {
  'usertype' => 'customer',
  'token' => 'd',
  'full_name' =>  'test name',
  'display_name' =>  'test name',
  'email' => 'dfsd@com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2006
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/invalid/i);

#Email exists
$testJson = {
  'usertype' => 'customer',
  'token' => 'd',
  'full_name' =>  'test name',
  'display_name' =>  'test name',
  'email' => 'a@b.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2006
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/already in use/i);

#postcode missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => 'd',
  'full_name' => 'test name',
  'display_name' => 'test name',
  'email' => 'd@e.com',
  'password' => 'Meh',
  'year_of_birth' => 2006
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no postcode sent/i);

#TODO validate postcode

#password missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => 'd',
  'full_name' => 'test name',
  'display_name' => 'test name',
  'email' => 'd@e.com',
  'postcode' => 'LA1 1AA',
  'year_of_birth' => 2006
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no password sent/i);

#TODO enforce password complexity requirements.

#usertype missing JSON
$testJson = {
  'token' => 'f',
  'full_name' => 'test name',
  'display_name' => 'test name',
  'email' => 'd@e.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 2006
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no usertype sent/i);

#Invalid user type
$testJson = {
  'usertype' => 'organisation1',
  'token' => 'f',
  'name' =>  'test name',
  'email' => 'org@org.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/usertype/i)
  ->content_like(qr/invalid/i);


#year_of_birth missing JSON
$testJson = {
  'usertype' => 'customer',
  'token' => 'f',
  'display_name' => 'test name',
  'full_name' => 'test name',
  'email' => 'broke@example.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no year of birth sent/i);

#Age is invalid
$testJson = {
  'usertype' => 'customer',
  'token' => 'f',
  'full_name' =>  'test name',
  'display_name' =>  'test name',
  'email' => 'test@example.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'year_of_birth' => 'invalid'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/year of birth/i)
  ->content_like(qr/invalid/i);

#full address missing JSON
$testJson = {
  'usertype' => 'organisation',
  'token' => 'f',
  'name' =>  'test org',
  'email' => 'org@org.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'sector' => 'A',
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no street name sent/i);

#TODO Validation of full address

#Organisation valid
$testJson = {
  'usertype' => 'organisation',
  'token' => 'f',
  'name' =>  'org name',
  'email' => 'org@org.com',
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'street_name' => 'mary lane testing....',
  'town' => 'Lancaster',
  'sector' => 'A',
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

is $t->app->schema->resultset('User')->count, 4, 'Correct user count';
is $t->app->schema->resultset('Customer')->count, 3, 'Correct customer count';
is $t->app->schema->resultset('Organisation')->count, 1, 'Correct organisation count';

done_testing();
