use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;
my $dump_error = sub { diag $t->tx->res->dom->at('pre[id="error"]')->text };

my @account_tokens = ('a', 'b', 'c');

$schema->resultset('AccountToken')->populate([
  [ 'accounttokenname' ],
  map { [ $_ ] } @account_tokens,
]);

#This depends on "register.t", "login.t", "upload.t" and "admin-approve.t" working.

#Valid customer, this also tests that redirects are disabled for register.
print "test 1 - Create customer user account (Reno)\n";
my $emailReno = 'reno@shinra.energy';
my $passwordReno = 'turks';
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@account_tokens), 
  'username' =>  'Reno', 
  'email' => $emailReno, 
  'postcode' => 'E1 MP01', 
  'password' => $passwordReno, 
  'age' => 1
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 2 - Create organisation user account (Choco Billy)\n";
my $emailBilly = 'choco.billy@chocofarm.org';
my $passwordBilly = 'Choco';
$testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@account_tokens), 
  'username' =>  'ChocoBillysGreens', 
  'email' => $emailBilly, 
  'postcode' => 'E4 C12', 
  'password' => $passwordBilly, 
  'street_name' => 'Chocobo Farm, Eastern Continent',
  town => 'Gaia',
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);


print "test 3 - Create admin account\n";
my $emailAdmin = 'admin@foodloop.net';
my $passwordAdmin = 'ethics';
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@account_tokens), 
  'username' =>  'admin', 
  'email' => $emailAdmin, 
  'postcode' => 'NW1 W01', 
  'password' => $passwordAdmin, 
  'age' => 2
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 4 - Making 'admin' an Admin\n";
my $rufus_user = $schema->resultset('User')->find({ email => $emailAdmin });
is $schema->resultset('Administrator')->count, 0, "No admins";
$rufus_user->find_or_create_related('administrator', {});
is $schema->resultset('Administrator')->count, 1, "1 admin";

######################################################

#Login as non-admin Reno

print "test 5 - Login - non-admin Reno (cookies, customer)\n";
$testJson = {
  'email' => $emailReno,
  'password' => $passwordReno,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
my $session_key = $t->tx->res->json('/session_key');

print "test 6 - add valid transaction (type 3: new organisation)\n";
is $schema->resultset('PendingOrganisation')->count, 0, "No unverified organisations";
is $schema->resultset('PendingTransaction')->count,  0, "No unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

my $nameToTestTurtle = 'Turtle\'s Paradise';
my $json = {
  transaction_value => 20,
  transaction_type => 3,
  organisation_name => $nameToTestTurtle,
  street_name => "Town centre",
  town => " Wutai",
  postcode => "NW10 8HH",
  session_key => $session_key,
};
my $upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 1, "1 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  1, "1 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

my $newPendingTurtleOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestTurtle })->id;
print "Turtle Id: " . $newPendingTurtleOrgId . "\n";


print "test 7 - Logout Reno\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of non-admin Reno

######################################################

#Login as non-admin Choco Billy

print "test 8 - Login - non-admin Choco Billy (cookies, organisation)\n";
$testJson = {
  'email' => $emailBilly,
  'password' => $passwordBilly,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 9 - add valid transaction (type 3: new organisation)\n";
is $schema->resultset('PendingOrganisation')->count, 1, "1 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  1, "1 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

my $nameToTestTurtlePartial = 'Turtle\'s Paradise2';
$json = {
  transaction_value => 20,
  transaction_type => 3,
  organisation_name => $nameToTestTurtlePartial,
  street_name => "",
  town => "Turtlesville",
  postcode => "",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)->or($dump_error)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 2, "2 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  2, "2 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

my $newPendingTurtleOrgIdPartial = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestTurtlePartial })->id;
print "Turtle Id 2: " . $newPendingTurtleOrgIdPartial . "\n";

#done_testing();
#exit;


print "test 10 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  organisation_id => $newPendingTurtleOrgIdPartial,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 2, "2 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  3, "3 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

print "test 11 - add valid transaction (type 3: new organisation)\n";
my $nameToTestJunon = 'Store';
$json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => $nameToTestJunon,
  street_name => "Main street",
  town => "Under Junon",
  postcode => "NW9 5EB",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

my $newPendingJunonOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestJunon })->id;
print "Junon Id: " . $newPendingJunonOrgId . "\n";

is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  4, "4 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

print "test 12 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  transaction_value => 20,
  transaction_type => 2,
  organisation_id => $newPendingJunonOrgId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  5, "5 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

print "test 13 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  transaction_value => 30,
  transaction_type => 2,
  organisation_id => $newPendingJunonOrgId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  6, "6 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";

print "test 14 - Logout Choco Billy\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of non-admin Choco Billy

######################################################

#Login as Admin

print "test 15 - Login - admin\n";
$testJson = {
  'email' => $emailAdmin,
  'password' => $passwordAdmin,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 16 - Admin - Approve the correctly filled out organisation.\n";
is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  6, "6 unverified transactions";
is $schema->resultset('Organisation')->count,        1, "1 verified organisation";
is $schema->resultset('Transaction')->count,         0, "No verified transactions";
$json = {
  pending_organisation_id => $newPendingTurtleOrgId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

my $turtleValidatedId = $t->app->schema->resultset('Organisation')->find({ name => $nameToTestTurtle })->id;
is $schema->resultset('PendingOrganisation')->count, 2, "2 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  5, "5 unverified transactions";
is $schema->resultset('Organisation')->count,        2, "2 verified organisation";
is $schema->resultset('Transaction')->count,         1, "1 verified transactions";

print "test 17 - Logout Admin\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of Admin

######################################################

#Login as non-admin Choco Billy

print "test 18 - Login - non-admin Choco Billy (cookies, organisation)\n";
$testJson = {
  'email' => $emailBilly,
  'password' => $passwordBilly,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 19 - Attempt to merge own unvalidated organisation with validated one and fails.\n";
$json = {
  pending_organisation_id => $newPendingTurtleOrgIdPartial,
  target_organisation_id => $turtleValidatedId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Not Authorised/i);

print "test 20 - Logout Choco Billy\n";
$t->post_ok('/api/logout', json => { session_key => $session_key })
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of non-admin Choco Billy

######################################################

#Login as Admin

print "test 21 - Login - admin\n";
$testJson = {
  'email' => $emailAdmin,
  'password' => $passwordAdmin,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 22 - JSON is missing.\n";
$t->post_ok('/api/admin-merge' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/);


print "test 23 - pending_organisation_id missing.\n";
$json = {
  target_organisation_id => $turtleValidatedId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/pending_organisation_id is missing/i);


print "test 24 - pending_organisation_id not number.\n";
$json = {
  pending_organisation_id => "ABC",
  target_organisation_id => $turtleValidatedId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/pending_organisation_id is not a number/i);


print "test 25 - target_organisation_id missing.\n";
$json = {
  pending_organisation_id => $newPendingTurtleOrgIdPartial,
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/target_organisation_id is missing/i);


print "test 26 - target_organisation_id not number.\n";
$json = {
  pending_organisation_id => $newPendingTurtleOrgIdPartial,
  target_organisation_id => "ABC",
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/target_organisation_id is not a number/i);


print "test 27 - pending_organisation_id does not exist.\n";
my $maxPendingId = $schema->resultset('PendingOrganisation')->get_column('id')->max;
$json = {
  pending_organisation_id => ($maxPendingId + 1),
  target_organisation_id => $turtleValidatedId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/pending_organisation_id does not exist in the database/i);


print "test 28 - target_organisation_id does not exist.\n";
my $maxId = $schema->resultset('Organisation')->get_column('id')->max;
$json = {
  pending_organisation_id => $newPendingTurtleOrgIdPartial,
  target_organisation_id => ($maxId + 1),
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/target_organisation_id does not exist in the database/i);

my $turtle_result = $schema->resultset('Organisation')->find($turtleValidatedId);
my $old_name = $turtle_result->name;
my $old_street_name = $turtle_result->street_name;
my $old_postcode = $turtle_result->postcode;
my $old_town = $turtle_result->town;

print "test 29 - valid merge.\n";
is $schema->resultset('PendingOrganisation')->count, 2, "2 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  5, "5 unverified transactions";
is $schema->resultset('Organisation')->count,        2, "2 verified organisation";
is $schema->resultset('Transaction')->count,         1, "1 verified transactions";
is $turtle_result->transactions->count, 1, '1 transactions for turtle';
$json = {
  pending_organisation_id => $newPendingTurtleOrgIdPartial,
  target_organisation_id => $turtleValidatedId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-merge' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 1, "1 unverified organisations";
is $schema->resultset('PendingTransaction')->count,  3, "3 unverified transactions";
is $schema->resultset('Organisation')->count,        2, "2 verified organisation";
is $schema->resultset('Transaction')->count,         3, "3 verified transactions";
is $turtle_result->transactions->count, 3, '3 transactions for turtle';
is $turtle_result->name, $old_name, 'name unchanged';
is $turtle_result->town, $old_town, 'town unchanged';
is $turtle_result->postcode, $old_postcode, 'postcode unchanged';
is $turtle_result->street_name, $old_street_name, 'street_name unchanged';

done_testing();
