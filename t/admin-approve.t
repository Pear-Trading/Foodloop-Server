use Test::More;
use Test::Mojo;
use Mojo::JSON;

use FindBin;

$ENV{MOJO_MODE} = 'development';
$ENV{MOJO_LOG_LEVEL} = 'debug';

my $t = Test::Mojo->new("Pear::LocalLoop");

my $dbh = $t->app->db;

#Dump all pf the test tables and start again.
my $sqlDeployment = Mojo::File->new("$FindBin::Bin/../dropschema.sql")->slurp;
for (split ';', $sqlDeployment){
  $dbh->do($_) or die $dbh->errstr;
}

my $sqlDeployment = Mojo::File->new("$FindBin::Bin/../schema.sql")->slurp;
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
$t->post_ok('/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 2 - Create organisation user account (Choco Billy)\n";
my $emailBilly = 'choco.billy@chocofarm.org';
my $passwordBilly = 'Choco';
my $testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@accountTokens), 
  'username' =>  'ChocoBillysGreens', 
  'email' => $emailBilly, 
  'postcode' => 'E4 C12', 
  'password' => $passwordBilly, 
  'fulladdress' => 'Chocobo Farm, Eastern Continent, Gaia'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);


print "test 3 - Create admin account\n";
my $emailAdmin = 'admin@foodloop.net';
my $passwordAdmin = 'ethics';
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@accountTokens), 
  'username' =>  'admin', 
  'email' => $emailAdmin, 
  'postcode' => 'NW1 W01', 
  'password' => $passwordAdmin, 
  'age' => '35-50'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 3 - Making 'admin' an Admin\n";
my $rufusUserId = $t->app->db->selectrow_array("SELECT UserId FROM Users WHERE Email = ?", undef, ($emailAdmin));
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Administrators")}[0],0,"No admins";
$t->app->db->prepare("INSERT INTO Administrators (UserId) VALUES (?)")->execute($rufusUserId);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Administrators")}[0],1,"1 admin";


######################################################

#Login as non-admin Reno

print "test 4 - Login - non-admin Reno (cookies, customer)\n";
$testJson = {
  'email' => $emailReno,
  'password' => $passwordReno,
};
$t->post_ok('/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 5 - add valid transaction (type 3: new organisation)\n";
my ($test1) = $t->app->db->selectrow_array("SELECT COUNT(*) FROM PendingOrganisations", undef, ());
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],0,"No unverified organisations.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],0,"No unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisation (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;
my $nameToTestTurtle = 'Turtle\'s Paradise';
$json = {
  microCurrencyValue => 20,
  transactionAdditionType => 3,
  organisationName => $nameToTestTurtle,
  streetName => "Town centre",
  town => " Wutai",
  postcode => "NW1 W01"
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/unvalidatedOrganisationId');
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],1,"1 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

my $newPendingTurtleOrgId = $t->tx->res->json->{unvalidatedOrganisationId};;
#print "Turtle Id: " . $newPendingTurtleOrgId . "\n";

print "test 6 - Non-admin (customer) tries to approve their organisation and fails.\n";
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgId,
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/You are not an admin/i);


print "test 7 - Logout Reno\n";
$t->post_ok('/logout')
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
$t->post_ok('/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);


print "test 9 - add valid transaction (type 3: new organisation)\n";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],1,"1 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;
my $nameToTestKalm = 'Kalm Inn';
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 3,
  organisationName => $nameToTestKalm,
  streetName => "Town centre",
  town => "Kalm",
  postcode => "E2 M02"
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/unvalidatedOrganisationId');
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],2,"2 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

my $newPendingKalmOrgId = $t->tx->res->json->{unvalidatedOrganisationId};
#print "Kalm Id: " . $newPendingKalmOrgId . "\n";


print "test 10 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 2,
  addUnvalidatedId => $newPendingKalmOrgId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_hasnt('/unvalidatedOrganisationId');
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],3,"3 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

print "test 11 - add valid transaction (type 3: new organisation)\n";
my $nameToTestJunon = 'Store';
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 3,
  organisationName => $nameToTestJunon,
  streetName => "Main street",
  town => "Under Junon",
  postcode => "E6 M02"
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/unvalidatedOrganisationId');

my $newPendingJunonOrgId = $t->tx->res->json->{unvalidatedOrganisationId};
#print "Junon Id: " . $newPendingJunonOrgId . "\n";

is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],4,"4 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;



print "test 12 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  microCurrencyValue => 20,
  transactionAdditionType => 2,
  addUnvalidatedId => $newPendingJunonOrgId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_hasnt('/unvalidatedOrganisationId');
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],5,"5 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;



print "test 13 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  microCurrencyValue => 30,
  transactionAdditionType => 2,
  addUnvalidatedId => $newPendingJunonOrgId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_hasnt('/unvalidatedOrganisationId');
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],6,"6 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

print "test 14 - Non-admin (organisation) tries to approve their organisation and fails.\n";
$json = {
  unvalidatedOrganisationId => $newPendingKalmOrgId,
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/You are not an admin/i);

print "test 15 - Logout Choco Billy\n";
$t->post_ok('/logout')
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#End of non-admin Choco Billy

######################################################

#Login as Admin

print "test 16 - Login - admin\n";
$testJson = {
  'email' => $emailAdmin,
  'password' => $passwordAdmin,
};
$t->post_ok('/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);


print "test 17 - JSON is missing.\n";
$t->post_ok('/admin-approve' => json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/JSON is missing/i);

print "test 18 - unvalidatedOrganisationId missing (non-modify).\n";
$json = {
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/unvalidatedOrganisationId is missing/i);

print "test 19 - unvalidatedOrganisationId not number (non-modify).\n";
$json = {
  unvalidatedOrganisationId => 'Abc',
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/unvalidatedOrganisationId does not look like a number/i);


print "test 20 - unvalidatedOrganisationId does not exist (non-modify).\n";
my ($maxPendingId) = $t->app->db->selectrow_array("SELECT MAX(PendingOrganisationId) FROM PendingOrganisations", undef,());
$json = {
  unvalidatedOrganisationId => ($maxPendingId + 1),
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/the specified unvalidatedOrganisationId does not exist/i);

#TODO add text to see the specific one has moved.

print "test 21 - valid approval (non-modify).\n";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations."; 
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],6,"6 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified organisations.";  
$json = {
  unvalidatedOrganisationId => $newPendingKalmOrgId,
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],4,"4 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],2,"2 verified organisations (choco billy and kalm inn)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],2,"2 verified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations WHERE Name = ?", undef, ($nameToTestKalm))}[0],0,"Kalm does not exist in pending orgs.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ?", undef, ($nameToTestKalm))}[0],1,"Kalm exists in verified orgs.";

#TODO check with values missing

print "test 22 - valid approval (non-modify).\n";
#TODO if we implement constraints on the input data this will fail
my $testName = "Change testing turtle name";
my $testFullAddress = "Change testing turtle address";
my $testPostCode = "Change testing turtle postcode";
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgId,
  name => $testName,
  fullAddress => $testFullAddress,
  postCode => $testPostCode,
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],3,"3 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],3,"3 verified organisations (choco billy, kalm inn and turtle)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],3,"3 verified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations WHERE Name = ?", undef, ($nameToTestTurtle))}[0],0,"Turtle does not exist in pending orgs.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ?", undef, ($nameToTestTurtle))}[0],0,"Turtle does not exist in verified orgs, it been renamed.";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE Name = ? AND FullAddress = ? AND PostCode = ?", undef, ($testName, $testFullAddress, $testPostCode))}[0],1,"Turtle exists and has been renamed in verified orgs.";

##############################################



done_testing();
