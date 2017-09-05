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

#Add a test purchase_time to use for receipt uploading.
my $test_purchase_time = "2017-08-14T11:29:07.965+01:00";

#Add one company that we've apparently authenticated but does not have an account.

my $org_rs = $schema->resultset('Organisation');

is $org_rs->count, 0, "No organisations";
my $shinra_entity = $schema->resultset('Entity')->create_org({
  name => 'Shinra Electric Power Company',
  street_name => 'Sector 0, Midgar, Eastern Continent',
  town => 'Gaia',
  postcode => 'E1 M00',
  submitted_by_id => 1,
});
is $org_rs->count, 1, "1 testing organisation";

my $org_id_shinra = $shinra_entity->organisation->id;

#Valid customer, this also tests that redirects are disabled for register.
print "test 1 - Create customer user account (Rufus)\n";
my $emailRufus = 'test1@example.com';
my $passwordRufus = 'abc123';
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@account_tokens),
  'full_name' =>  'RufusShinra',
  'display_name' =>  'RufusShinra',
  'email' => $emailRufus,
  'postcode' => 'GU10 5SA',
  'password' => $passwordRufus,
  'year_of_birth' => 2006
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
  'display_name' =>  'ProfessorHojo',
  'full_name' =>  'ProfessorHojo',
  'email' => $emailHojo,
  'postcode' => 'DE15 9LT',
  'password' => $passwordHojo,
  'year_of_birth' => 2006
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
  'name' =>  'ChocoBillysGreens',
  'email' => $emailBilly,
  'postcode' => 'SO50 7NJ',
  'password' => $passwordBilly,
  'street_name' => 'Chocobo Farm, Eastern Continent',
  'town' => 'Gaia',
  'sector' => 'A',
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
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
  organisation_id => 1,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json)};
$t->post_ok('/api/upload' => form => $upload )
->status_is(200)
->or($framework->dump_error)
->json_is('/success', Mojo::JSON->true)
->json_like('/message', qr/Upload Successful/);
is $schema->resultset('Transaction')->count, 1, "1 transaction";

print "test 13 - organisation_id missing (type 1: already validated)\n";
$json = {
  transaction_value => 10,
  transaction_type => 1,
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
  organisation_id => ($org_id_shinra + 100),
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id does not exist in the database/i);

print "test 15 - valid addition. (type 1: already validated)\n";
is $schema->resultset('Transaction')->count, 1, "1 transaction";
$json = {
  transaction_value => 10,
  transaction_type => 1,
  purchase_time => $test_purchase_time,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is $schema->resultset('Transaction')->count, 2, "2 transaction";

# Add type 3 (new organisation) checking.

print "test 16 - organsation missing (type 3: new organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 3,
  purchase_time => $test_purchase_time,
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
is $schema->resultset('Organisation')->search({ pending => 1 })->count, 0, "No pending organisations";
is $schema->resultset('Organisation')->search({ pending => 1 })->entity->sales->count, 0, "No pending transactions";

$json = {
  transaction_value => 10,
  transaction_type => 3,
  purchase_time => $test_purchase_time,
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
is $schema->resultset('Organisation')->search({ pending => 1 })->count, 1, "1 pending organisations";
is $schema->resultset('Organisation')->search({ pending => 1 })->entity->sales->count, 1, "1 pending transactions";

# Add type 2 (unverified organisation) checking.

print "test 18 - organisation_id missing (type 2: existing organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  purchase_time => $test_purchase_time,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id is missing/i);

print "test 19 - organisation_id not a number (type 2: existing organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  purchase_time => $test_purchase_time,
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
  purchase_time => $test_purchase_time,
  organisation_id => 1000, #Id that does not exist
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id does not exist in the database/i);

print "test 21 - purchase_time is missing\n";
is $schema->resultset('Organisation')->search({ pending => 1 })->entity->sales->count, 1, "1 pending transactions";
$json = {
  transaction_value => 10,
  transaction_type => 1,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 22 - Logout Rufus (type 2: existing organisation)\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of Rufus (customer)

######################################################

#Login as Hojo (customer)

print "test 23 - Login Hojo (cookies, customer)\n";
$testJson = {
  'email' => $emailHojo,
  'password' => $passwordHojo,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 24 - add valid transaction but for with account (type 2: existing organisation)\n";
my $org_result = $schema->resultset('Organisation')->find({ name => '7th Heaven' });
my $unvalidatedOrganisationId = $org_result->id;
is $schema->resultset('Organisation')->search({ pending => 1 })->entity->sales->count, 1, "1 pending transactions";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  purchase_time => $test_purchase_time,
  organisation_id => $unvalidatedOrganisationId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisation_id does not exist in the database/i);
is $schema->resultset('Organisation')->search({ pending => 1 })->entity->sales->count, 1, "1 pending transactions";

print "test 25 - Logout Hojo\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of Hojo (customer)

######################################################

#Login as Rufus (customer)

print "test 26 - Login Rufus (cookies, customer)\n";
$testJson = {
  'email' => $emailRufus,
  'password' => $passwordRufus,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 27 - add valid transaction (type 2: existing organisation)\n";
is $schema->resultset('Organisation')->search({ pending => 1 })->entity->sales->count, 1, "1 pending transactions";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  purchase_time => $test_purchase_time,
  organisation_id => $unvalidatedOrganisationId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is $schema->resultset('Organisation')->search({ pending => 1 })->entity->sales->count, 2, "2 pending transactions";


print "test 28 - Logout Rufus\n";
$t->post_ok('/api/logout' => json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of Rufus (customer)

######################################################

#Login as Choco Billy (organisation)

print "test 29 - Login Choco Billy (cookies, organisation)\n";
$testJson = {
  'email' => $emailBilly,
  'password' => $passwordBilly,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
$session_key = $t->tx->res->json('/session_key');

print "test 30 - organisation buy from another organisation\n";
is $schema->resultset('Transaction')->count, 5, "5 transaction";
$json = {
  transaction_value => 100000,
  transaction_type => 1,
  purchase_time => $test_purchase_time,
  organisation_id => $org_id_shinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is $schema->resultset('Transaction')->count, 6, "6 transaction";

print "test 31 - organisation buy from same organisation\n";
$json = {
  transaction_value => 100000,
  transaction_type => 1,
  purchase_time => $test_purchase_time,
  organisation_id => 2,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/organisation_id does not exist in the database/);
is $schema->resultset('Transaction')->count, 6, "6 transaction";

done_testing();
