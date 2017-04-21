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

#Add one company that we've apparently authenticated but does not have an account.
my $org_id_shinra = 1;

my $org_rs = $schema->resultset('Organisation');

is $org_rs->count, 0, "No organisations";
$org_rs->create({
  id => $org_id_shinra,
  name => 'Shinra Electric Power Company',
  street_name => 'Sector 0, Midgar, Eastern Continent',
  town => 'Gaia',
  postcode => 'E1 M00',
});
is $org_rs->count, 1, "1 testing organisation";

#Valid customer, this also tests that redirects are disabled for register.
print "test 1 - Create customer user account (Rufus)\n";
my $emailRufus = 'rufus@shinra.energy';
my $passwordRufus = 'MakoGold';
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@account_tokens), 
  'username' =>  'RufusShinra', 
  'email' => $emailRufus, 
  'postcode' => 'E1 MP01', 
  'password' => $passwordRufus, 
  'age' => 1
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 2 - Create customer user account (Hojo)\n";
my $emailHojo = 'hojo@shinra.energy';
my $passwordHojo = 'Mako';
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@account_tokens), 
  'username' =>  'ProfessorHojo', 
  'email' => $emailHojo, 
  'postcode' => 'E1 MP01', 
  'password' => $passwordHojo, 
  'age' => 1
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 3 - Create organisation user account (Choco Billy)\n";
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
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Registered Successfully/);

######################################################

#Login as Hojo (customer)

#Test login, this also checks that redirects are disabled for login when logged out.
print "test 4 - Login - Rufus (cookies, customer)\n";
$testJson = {
  'email' => $emailRufus,
  'password' => $passwordRufus,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
my $session_key = $t->tx->res->json('/session_key');
print "test 5 - JSON missing\n";
my $upload = {file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/);

#TODO Check for malformed JSON.

print "test 6 - transaction_value missing\n";
my $json = {
  transaction_type => 1,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transaction_value is missing/i);

print "test 7 - transaction_value non-numbers\n";
$json = {
  transaction_value => 'Abc',
  transaction_type => 1,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transaction_value does not look like a number/i);

print "test 8 - transaction_value equal to zero\n";
$json = {
  transaction_value => 0,
  transaction_type => 1,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transaction_value cannot be equal to or less than zero/i);

print "test 9 - transaction_value less than zero\n";
$json = {
  transaction_value => -1,
  transaction_type => 1,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transaction_value cannot be equal to or less than zero/i);

print "test 10 - transaction_type missing\n";
$json = {
  transaction_value => 10,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transaction_type is missing/i);

print "test 11 - transaction_type invalid.\n";
$json = {
  transaction_value => 10,
  transaction_type => 4,
  session_key => $session_key,
#  organisation_id => $org_id_shinra
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transaction_type is not a valid value/i);

print "test 12 - file not uploaded.\n";
$json = {
  transaction_value => 10,
  transaction_type => 1,
  organisation_id => 1,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json)};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no file uploaded/i);

print "test 13 - organisation_id missing (type 1: already validated)\n";
$json = {
  transaction_value => 10,
  transaction_type => 1,
  session_key => $session_key,
#  organisation_id => $org_id_shinra
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id is missing/i);

print "test 14 - organisation_id for non-existent id. (type 1: already validated)\n";
$json = {
  transaction_value => 10,
  transaction_type => 1,
  organisation_id => ($org_id_shinra + 100),
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id does not exist in the database/i);

print "test 15 - valid addition. (type 1: already validated)\n";
is $schema->resultset('Transaction')->count, 0, "no transactions";
$json = {
  transaction_value => 10,
  transaction_type => 1,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is $schema->resultset('Transaction')->count, 1, "1 transaction";

# Add type 3 (new organisation) checking.

print "test 16 - organsation missing (type 3: new organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 3,
  street_name => "Slums, Sector 7",
  town => "Midgar",
  postcode => "E1 0AA",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_name is missing/i);

print "test 17 - add valid transaction (type 3: new organisation)\n";
is $schema->resultset('PendingOrganisation')->count, 0, "No pending organisations";
is $schema->resultset('PendingTransaction')->count, 0, "No pending transactions";

$json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => '7th Heaven',
  street_name => "Slums, Sector 7",
  town => "Midgar",
  postcode => "E1 0AA",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is $schema->resultset('PendingOrganisation')->count, 1, "1 pending organisations";
is $schema->resultset('PendingTransaction')->count, 1, "1 pending transactions";

# Add type 2 (unverified organisation) checking.

print "test 18 - organisation_id missing (type 2: existing organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id is missing/i);

print "test 19 - organisation_id not a number (type 2: existing organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  organisation_id => "Abc",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id is not a number/i);

print "test 20 - id does not exist (type 2: existing organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  organisation_id => 1000, #Id that does not exist
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id does not exist in the database/i);

print "test 21 - Logout Rufus (type 2: existing organisation)\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of Rufus (customer)

######################################################

#Login as Hojo (customer)

print "test 22 - Login Hojo (cookies, customer)\n";
$testJson = {
  'email' => $emailHojo,
  'password' => $passwordHojo,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 23 - add valid transaction but for with account (type 2: existing organisation)\n";
my $org_result = $schema->resultset('PendingOrganisation')->find({ name => '7th Heaven' });
my $unvalidatedOrganisationId = $org_result->id;
is $schema->resultset('PendingTransaction')->count, 1, "1 pending transactions";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  organisation_id => $unvalidatedOrganisationId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id does not exist in the database/i);
is $schema->resultset('PendingTransaction')->count, 1, "1 pending transactions";

print "test 24 - Logout Hojo\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of Hojo (customer)

######################################################

#Login as Rufus (customer)

print "test 25 - Login Rufus (cookies, customer)\n";
$testJson = {
  'email' => $emailRufus,
  'password' => $passwordRufus,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 26 - add valid transaction (type 2: existing organisation)\n";
is $schema->resultset('PendingTransaction')->count, 1, "1 pending transactions";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  organisation_id => $unvalidatedOrganisationId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is $schema->resultset('PendingTransaction')->count, 2, "2 pending transactions";


print "test 27 - Logout Rufus\n";
$t->post_ok('/api/logout' => json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of Rufus (customer)

######################################################

#Login as Choco Billy (organisation)

print "test 28 - Login Choco Billy (cookies, organisation)\n";
$testJson = {
  'email' => $emailBilly,
  'password' => $passwordBilly,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 29 - organisation buy from another organisation\n";
is $schema->resultset('Transaction')->count, 1, "1 transaction";
$json = {
  transaction_value => 100000,
  transaction_type => 1,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is $schema->resultset('Transaction')->count, 2, "2 transaction";

done_testing();

