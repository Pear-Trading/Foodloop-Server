use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::JSON;

use FindBin;

BEGIN {
  $ENV{MOJO_MODE} = 'testing';
  $ENV{MOJO_LOG_LEVEL} = 'debug';
}

my $t = Test::Mojo->new("Pear::LocalLoop");

my $dbh = $t->app->db;

#Dump all pf the test tables and start again.
my $sqlDeployment = Mojo::File->new("$FindBin::Bin/../dropschema.sql")->slurp;
for (split ';', $sqlDeployment){
  $dbh->do($_) or die $dbh->errstr;
}

$sqlDeployment = Mojo::File->new("$FindBin::Bin/../schema.sql")->slurp;
for (split ';', $sqlDeployment){
  $dbh->do($_) or die $dbh->errstr;
}

my @accountTokens = ('a', 'b', 'c');
my $tokenStatement = $dbh->prepare('INSERT INTO AccountTokens (AccountTokenName) VALUES (?)');
foreach (@accountTokens){
  my $rowsAdded = $tokenStatement->execute($_);
}


#This depends on "register.t", "login.t" and "upload.t" working.

#Valid customer, this also tests that redirects are disabled for register.
print "test 1 - Create customer user account (Reno)\n";
my $emailReno = 'reno@shinra.energy';
my $passwordReno = 'turks';
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@accountTokens), 
  'username' =>  'Reno', 
  'email' => $emailReno, 
  'postcode' => 'E1 MP01', 
  'password' => $passwordReno, 
  'age' => '20-35'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 2 - Create organisation user account (Choco Billy)\n";
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


print "test 3 - Create admin account\n";
my $emailAdmin = 'admin@foodloop.net';
my $passwordAdmin = 'ethics';
$testJson = {
  'usertype' => 'customer', 
  'token' => shift(@accountTokens), 
  'username' =>  'admin', 
  'email' => $emailAdmin, 
  'postcode' => 'NW1 W01', 
  'password' => $passwordAdmin, 
  'age' => '35-50'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 4 - Making 'admin' an Admin\n";
my $rufusUserId = $t->app->db->selectrow_array("SELECT UserId FROM Users WHERE Email = ?", undef, ($emailAdmin));
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Administrators")}[0],0,"No admins";
$t->app->db->prepare("INSERT INTO Administrators (UserId) VALUES (?)")->execute($rufusUserId);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Administrators")}[0],1,"1 admin";


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
my ($test1) = $t->app->db->selectrow_array("SELECT COUNT(*) FROM PendingOrganisations", undef, ());
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],0,"No unverified organisations.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],0,"No unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisation (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;
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
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],1,"1 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

my $newPendingTurtleOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestTurtle })->pendingorganisationid;
#print "Turtle Id: " . $newPendingTurtleOrgId . "\n";

print "test 7 - Non-admin (customer) tries to approve their organisation and fails.\n";
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/You are not an admin/i);


print "test 8 - Logout Reno\n";
$t->post_ok('/api/logout', json => { session_key => $session_key } )
  ->status_is(200)
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
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],1,"1 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;
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
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],2,"2 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

my $newPendingKalmOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestKalm })->pendingorganisationid;
#print "Kalm Id: " . $newPendingKalmOrgId . "\n";


print "test 11 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  transaction_value => 10,
  transaction_type => 2,
  organisation_id => $newPendingKalmOrgId,
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],3,"3 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

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

my $newPendingJunonOrgId = $t->app->schema->resultset('PendingOrganisation')->find({ name => $nameToTestJunon })->pendingorganisationid;
#print "Junon Id: " . $newPendingJunonOrgId . "\n";

is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],4,"4 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;


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
  ->json_is('/success', Mojo::JSON->true)
  ->json_hasnt('/unvalidatedOrganisationId');
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],5,"5 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;


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
  ->json_is('/success', Mojo::JSON->true)
  ->json_hasnt('/unvalidatedOrganisationId');
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],6,"6 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

print "test 15 - Non-admin (organisation) tries to approve their organisation and fails.\n";
$json = {
  unvalidatedOrganisationId => $newPendingKalmOrgId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/You are not an admin/i);

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

print "test 19 - unvalidatedOrganisationId missing (non-modify).\n";
$json = {
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/unvalidatedOrganisationId is missing/i);

print "test 20 - unvalidatedOrganisationId not number (non-modify).\n";
$json = {
  unvalidatedOrganisationId => 'Abc',
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/unvalidatedOrganisationId does not look like a number/i);


print "test 21 - unvalidatedOrganisationId does not exist (non-modify).\n";
my ($maxPendingId) = $t->app->db->selectrow_array("SELECT MAX(PendingOrganisationId) FROM PendingOrganisations", undef,());
$json = {
  unvalidatedOrganisationId => ($maxPendingId + 1),
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/the specified unvalidatedOrganisationId does not exist/i);

#TODO add text to see the specific one has moved.

print "test 22 - valid approval (non-modify).\n";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations."; 
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],6,"6 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified organisations.";  
$json = {
  unvalidatedOrganisationId => $newPendingKalmOrgId,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],4,"4 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],2,"2 verified organisations (choco billy and kalm inn)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],2,"2 verified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations WHERE Name = ?", undef, ($nameToTestKalm))}[0],0,"Kalm does not exist in pending orgs.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ?", undef, ($nameToTestKalm))}[0],1,"Kalm exists in verified orgs.";

print "test 23 - valid approval (modify all).\n";
#TODO if we implement constraints on the input data this will fail
my $testName = "Change testing turtle name";
my $testFullAddress = "Change testing turtle address";
my $testPostCode = "Change testing turtle postcode";
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgId,
  name => $testName,
  fullAddress => $testFullAddress,
  postCode => $testPostCode,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],3,"3 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],3,"3 verified organisations (choco billy, kalm inn and turtle)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],3,"3 verified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations WHERE Name = ?", undef, ($nameToTestTurtle))}[0],0,"Turtle does not exist in pending orgs.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ?", undef, ($nameToTestTurtle))}[0],0,"Turtle does not exist in verified orgs, its been renamed.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ? AND FullAddress = ? AND PostCode = ?", undef, ($testName, $testFullAddress, $testPostCode))}[0],1,"Turtle exists and has been renamed in verified orgs.";

print "test 24 - valid approval (modify some).\n";
#TODO if we implement constraints on the input data this will fail
$testName = "Change testing junon name";
$json = {
  unvalidatedOrganisationId => $newPendingJunonOrgId,
  name => $testName,
  session_key => $session_key,
};
$t->post_ok('/api/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],0,"0 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],0,"0 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],4,"4 verified organisations (choco billy, kalm inn, turtle and junon)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],6,"6 verified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations WHERE Name = ?", undef, ($nameToTestJunon))}[0],0,"Junon does not exist in pending orgs.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ?", undef, ($nameToTestJunon))}[0],0,"Junon does not exist in verified orgs, its been renamed.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ?", undef, ($testName))}[0],1,"Junon exists and has been renamed in verified orgs.";

##############################################

done_testing();
