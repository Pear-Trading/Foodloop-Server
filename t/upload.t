use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

my @accountTokens = ('a', 'b', 'c');

$schema->resultset('AccountToken')->populate([
  [ 'accounttokenname' ],
  map { [ $_ ] } @accountTokens,
]);

#Add one company that we've apparently authenticated but does not have an account.
my $companyIdNumShinra = 1;
my $name = "Shinra Electric Power Company";
my $fullAddress = "Sector 0, Midgar, Eastern Continent, Gaia";
my $postcode = "E1 M00";

my $org_rs = $schema->resultset('Organisation');

is $org_rs->count, 0, "No organisations";
$org_rs->create({
  organisationalid => $companyIdNumShinra,
  name => $name,
  fulladdress => $fullAddress,
  postcode => $postcode,
});
is $org_rs->count, 1, "1 testing organisation";

#This depends on "register.t" and "login.t" working.

#Valid customer, this also tests that redirects are disabled for register.
print "test 1 - Create customer user account (Rufus)\n";
my $emailRufus = 'rufus@shinra.energy';
my $passwordRufus = 'MakoGold';
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@accountTokens), 
  'username' =>  'RufusShinra', 
  'email' => $emailRufus, 
  'postcode' => 'E1 MP01', 
  'password' => $passwordRufus, 
  'age' => '20-35'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 2 - Create customer user account (Hojo)\n";
my $emailHojo = 'hojo@shinra.energy';
my $passwordHojo = 'Mako';
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@accountTokens), 
  'username' =>  'ProfessorHojo', 
  'email' => $emailHojo, 
  'postcode' => 'E1 MP01', 
  'password' => $passwordHojo, 
  'age' => '35-50'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 3 - Create organisation user account (Choco Billy)\n";
my $emailBilly = 'choco.billy@chocofarm.org';
my $passwordBilly = 'Choco';
$testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@accountTokens), 
  'username' =>  'ChocoBillysGreens', 
  'email' => $emailBilly, 
  'postcode' => 'E4 C12', 
  'password' => $passwordBilly, 
  'fulladdress' => 'Chocobo Farm, Eastern Continent, Gaia'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);

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
my $upload = {file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/);

#TODO Check for malformed JSON.

print "test 6 - microCurrencyValue missing\n";
my $json = {
  transactionAdditionType => 1,
  addValidatedId => $companyIdNumShinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/microCurrencyValue is missing/i);

print "test 7 - microCurrencyValue non-numbers\n";
$json = {
  microCurrencyValue => 'Abc',
  transactionAdditionType => 1,
  addValidatedId => $companyIdNumShinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/microCurrencyValue does not look like a number/i);

print "test 8 - microCurrencyValue equal to zero\n";
$json = {
  microCurrencyValue => 0,
  transactionAdditionType => 1,
  addValidatedId => $companyIdNumShinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/microCurrencyValue cannot be equal to or less than zero/i);

print "test 9 - microCurrencyValue less than zero\n";
$json = {
  microCurrencyValue => -1,
  transactionAdditionType => 1,
  addValidatedId => $companyIdNumShinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/microCurrencyValue cannot be equal to or less than zero/i);

print "test 10 - transactionAdditionType missing\n";
$json = {
  microCurrencyValue => 10,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transactionAdditionType is missing/i);

print "test 11 - transactionAdditionType invalid.\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 4,
  session_key => $session_key,
#  addValidatedId => $companyIdNumShinra
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/transactionAdditionType is not a valid value/i);

print "test 12 - file not uploaded.\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 1,
  addValidatedId => 1,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json)};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no file uploaded/i);

print "test 13 - addValidatedId missing (type 1: already validated)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 1,
  session_key => $session_key,
#  addValidatedId => $companyIdNumShinra
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/addValidatedId is missing/i);

print "test 14 - addValidatedId for non-existent id. (type 1: already validated)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 1,
  addValidatedId => ($companyIdNumShinra + 100),
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/addValidatedId does not exist in the database/i);

print "test 15 - valid addition. (type 1: already validated)\n";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions")}[0],0,"no transactions";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 1,
  addValidatedId => $companyIdNumShinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions")}[0],1,"1 transaction";

# Add type 3 (new organisation) checking.

print "test 16 - organsation missing (type 3: new organisation)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 3,
  streetName => "Slums, Sector 7",
  town => "Midgar",
  postcode => "E1 0AA",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/organisationName is missing/i);

print "test 17 - add valid transaction (type 3: new organisation)\n";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations")}[0],0,"No pending organisations";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions")}[0],0,"No pending transactions";

$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 3,
  organisationName => '7th Heaven',
  streetName => "Slums, Sector 7",
  town => "Midgar",
  postcode => "E1 0AA",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations")}[0],1,"1 pending organisation";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions")}[0],1,"1 pending transaction";

# Add type 2 (unverified organisation) checking.

print "test 18 - addUnvalidatedId missing (type 2: existing organisation)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 2,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/addUnvalidatedId is missing/i);

print "test 19 - addUnvalidatedId not a number (type 2: existing organisation)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 2,
  addUnvalidatedId => "Abc",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/addUnvalidatedId does not look like a number/i);

print "test 20 - id does not exist (type 2: existing organisation)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 2,
  addUnvalidatedId => 1000, #Id that does not exist
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/addUnvalidatedId does not exist in the database for the user/i);

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
my $unvalidatedOrganisationId = $org_result->pendingorganisationid;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions")}[0],1,"1 pending transaction";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 2,
  addUnvalidatedId => $unvalidatedOrganisationId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/addUnvalidatedId does not exist in the database for the user/i);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions")}[0],1,"1 pending transaction";

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
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions")}[0],1,"1 pending transaction";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 2,
  addUnvalidatedId => $unvalidatedOrganisationId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions")}[0],2,"2 pending transaction";


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
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions")}[0],1,"1 transaction";
$json = {
  microCurrencyValue => 100000,
  transactionAdditionType => 1,
  addValidatedId => $companyIdNumShinra,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions")}[0],2,"2 transactions";

done_testing();

