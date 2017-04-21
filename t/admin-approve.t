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
  [ 'name' ],
  map { [ $_ ] } @account_tokens,
]);

#This depends on "register.t", "login.t" and "upload.t" working.

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
  ->status_is(200)->or($dump_error)
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
  'town' => 'Gaia',
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
  ->status_is(200)->or($dump_error)
  ->json_is('/success', Mojo::JSON->true);

my $session_key = $t->tx->res->json('/session_key');

print "test 6 - add valid transaction (type 3: new organisation)\n";
is $schema->resultset('PendingOrganisation')->count, 0, "No unverified organisations";
is $schema->resultset('PendingTransaction')->count, 0, "No unverified transactions" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;
my $nameToTestTurtle = 'Turtle\'s Paradise';
my $json = {
  transaction_value => 20,
  transaction_type => 3,
  organisation_name => $nameToTestTurtle,
  street_name => "Town centre",
  town => " Wutai",
  postcode => "NW1 5RU",
  session_key => $session_key,
};
my $upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)->or($dump_error)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 1, "1 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 1, "1 unverified transaction" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;

my $newPendingTurtleOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestTurtle })->id;
#print "Turtle Id: " . $newPendingTurtleOrgId . "\n";

print "test 7 - Non-admin (customer) tries to approve their organisation and fails.\n";
$json = {
  pending_organisation_id => $newPendingTurtleOrgId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Not Authorised/i);


print "test 8 - Logout Reno\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)->or($dump_error)
  ->json_is('/success', Mojo::JSON->true);

#End of non-admin Reno

######################################################

#Login as non-admin Choco Billy

print "test 9 - Login - non-admin Choco Billy (cookies, organisation)\n";
$testJson = {
  'email' => $emailBilly,
  'password' => $passwordBilly,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 10 - add valid transaction (type 3: new organisation)\n";
is $schema->resultset('PendingOrganisation')->count, 1, "1 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 1, "1 unverified transaction" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;

my $nameToTestKalm = 'Kalm Inn';
$json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => $nameToTestKalm,
  street_name => "Town centre",
  town => "Kalm",
  postcode => "NW11 7GZ",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

is $schema->resultset('PendingOrganisation')->count, 2, "2 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 2, "2 unverified transaction" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;

my $newPendingKalmOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestKalm })->id;

print "test 11 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  organisation_id => $newPendingKalmOrgId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)->or($dump_error)
  ->json_is('/success', Mojo::JSON->true);

is $schema->resultset('PendingOrganisation')->count, 2, "2 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 3, "3 unverified transaction" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;

print "test 12 - add valid transaction (type 3: new organisation)\n";
my $nameToTestJunon = 'Store';
$json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => $nameToTestJunon,
  street_name => "Main street",
  town => "Under Junon",
  postcode => "NW1W 7GF",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

my $newPendingJunonOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestJunon })->id;
#print "Junon Id: " . $newPendingJunonOrgId . "\n";
is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 4, "4 unverified transaction" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;

print "test 13 - add valid transaction (type 2: unvalidated organisation)\n";
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
is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 5, "5 unverified transaction" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;

print "test 14 - add valid transaction (type 2: unvalidated organisation)\n";
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
is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 6, "6 unverified transaction" ;
is $schema->resultset('Organisation')->count, 1, "1 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 0, "No verified transactions" ;

print "test 15 - Non-admin (organisation) tries to approve their organisation and fails.\n";
$json = {
  pending_organisation_id => $newPendingKalmOrgId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Not Authorised/i);

print "test 16 - Logout Choco Billy\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of non-admin Choco Billy

######################################################

#Login as Admin

print "test 17 - Login - admin\n";
$testJson = {
  'email' => $emailAdmin,
  'password' => $passwordAdmin,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 18 - JSON is missing.\n";
$t->post_ok('/api/admin-approve' => json => {})
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

print "test 19 - pending_organisation_id missing (non-modify).\n";
$json = {
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/pending_organisation_id is missing/i);

print "test 20 - pending_organisation_id not number (non-modify).\n";
$json = {
  pending_organisation_id => 'Abc',
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/pending_organisation_id is not a number/i);

print "test 21 - pending_organisation_id does not exist (non-modify).\n";

my $maxPendingId = $schema->resultset('PendingOrganisation')->get_column('id')->max;
$json = {
  pending_organisation_id => $maxPendingId + 1,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/pending_organisation_id does not exist in the database/i);

#TODO add text to see the specific one has moved.

print "test 22 - valid approval (non-modify).\n";
is $schema->resultset('PendingOrganisation')->count, 3, "3 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 6, "6 unverified transaction";
is $schema->resultset('Organisation')->count, 1, "1 verified organisation";
is $schema->resultset('Transaction')->count, 0, "No verified transactions";
$json = {
  pending_organisation_id => $newPendingKalmOrgId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(200)->or($dump_error)
  ->json_is('/success', Mojo::JSON->true);

is $schema->resultset('PendingOrganisation')->count, 2, "2 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 4, "4 unverified transaction";
is $schema->resultset('Organisation')->count, 2, "2 verified organisations";
is $schema->resultset('Transaction')->count, 2, "2 verified transactions";
is $schema->resultset('PendingOrganisation')->find({ name => $nameToTestKalm }), undef, "Kalm does not exist in pending orgs.";
ok $schema->resultset('Organisation')->find({ name => $nameToTestKalm }), "Kalm exists in verified orgs.";

print "test 23 - valid approval (modify all).\n";
#TODO if we implement constraints on the input data this will fail
my $test_name = "Change testing turtle name";
my $test_street_name = "Change testing turtle address";
my $test_town = "TestinTown";
my $test_postcode = "BN21 2RB";
$json = {
  pending_organisation_id => $newPendingTurtleOrgId,
  name => $test_name,
  street_name => $test_street_name,
  town => $test_town,
  postcode => $test_postcode,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 1, "1 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 3, "3 unverified transaction" ;
is $schema->resultset('Organisation')->count, 3, "3 verified organisation (choco billy)" ;
is $schema->resultset('Transaction')->count, 3, "3 verified transactions" ;
is $schema->resultset('PendingOrganisation')->find({ name => $nameToTestTurtle }), undef, "Turtle does not exist in pending orgs.";
is $schema->resultset('Organisation')->find({ name => $nameToTestTurtle }), undef, "original Turtle does not exists in verified orgs.";
my $turtle_result = $schema->resultset('Organisation')->find({ name => $test_name });
ok $turtle_result, "new Turtle exists in verified orgs.";
is $turtle_result->street_name, $test_street_name, 'street_name correct';
is $turtle_result->town, $test_town, 'town correct';
is $turtle_result->postcode, $test_postcode, 'postcode correct';

print "test 24 - valid approval (modify some).\n";
#TODO if we implement constraints on the input data this will fail
$test_name = "Change testing junon name";
$json = {
  pending_organisation_id => $newPendingJunonOrgId,
  name => $test_name,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is $schema->resultset('PendingOrganisation')->count, 0, "0 unverified organisation";
is $schema->resultset('PendingTransaction')->count, 0, "0 unverified transaction";
is $schema->resultset('Organisation')->count, 4, "4 verified organisations";
is $schema->resultset('Transaction')->count, 6, "6 verified transactions";
is $schema->resultset('PendingOrganisation')->find({ name => $nameToTestJunon }), undef, "Junon does not exist in pending orgs.";
is $schema->resultset('Organisation')->find({ name => $nameToTestJunon }), undef, "original Junon does not exists in verified orgs.";
my $junon_result = $schema->resultset('Organisation')->find({ name => $test_name });
ok $junon_result, "new Junon exists in verified orgs.";

##############################################

done_testing();
