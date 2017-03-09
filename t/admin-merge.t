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

my $sqlDeployment = Mojo::File->new("$FindBin::Bin/../schema.sql")->slurp;
for (split ';', $sqlDeployment){
  $dbh->do($_) or die $dbh->errstr;
}

my @accountTokens = ('a', 'b', 'c');
my $tokenStatement = $dbh->prepare('INSERT INTO AccountTokens (AccountTokenName) VALUES (?)');
foreach (@accountTokens){
  my $rowsAdded = $tokenStatement->execute($_);
}


#This depends on "register.t", "login.t", "upload.t" and "admin-approve.t" working.

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

print "test 4 - Making 'admin' an Admin\n";
my $adminUserId = $t->app->db->selectrow_array("SELECT UserId FROM Users WHERE Email = ?", undef, ($emailAdmin));
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Administrators")}[0],0,"No admins";
$t->app->db->prepare("INSERT INTO Administrators (UserId) VALUES (?)")->execute($adminUserId);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Administrators")}[0],1,"1 admin";


######################################################

#Login as non-admin Reno

print "test 5 - Login - non-admin Reno (cookies, customer)\n";
$testJson = {
  'email' => $emailReno,
  'password' => $passwordReno,
};
$t->post_ok('/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 6 - add valid transaction (type 3: new organisation)\n";
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
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],1,"1 unverified transaction." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

my $newPendingTurtleOrgId = $t->tx->res->json->{unvalidatedOrganisationId};
print "Turtle Id: " . $newPendingTurtleOrgId . "\n";


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

my $nameToTestTurtlePartial = 'Turtle\'s Paradise';
$json = {
  microCurrencyValue => 20,
  transactionAdditionType => 3,
  organisationName => $nameToTestTurtlePartial,
  streetName => "",
  town => "",
  postcode => ""
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],2,"2 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;

my $newPendingTurtleOrgIdPartial = $t->tx->res->json->{unvalidatedOrganisationId};;
print "Turtle Id 2: " . $newPendingTurtleOrgIdPartial . "\n";

#done_testing();
#exit;


print "test 10 - add valid transaction (type 2: unvalidated organisation)\n";
$json = {
  microCurrencyValue => 10,
  transactionAdditionType => 2,
  addUnvalidatedId => $newPendingTurtleOrgIdPartial,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
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
  ->json_is('/success', Mojo::JSON->true);

my $newPendingJunonOrgId = $t->tx->res->json->{unvalidatedOrganisationId};;
print "Junon Id: " . $newPendingJunonOrgId . "\n";

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
  ->json_is('/success', Mojo::JSON->true);
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
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],6,"6 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisations (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions." ;


print "test 14 - Logout Choco Billy\n";
$t->post_ok('/logout')
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
$t->post_ok('/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 16 - Admin - Approve the correctly filled out organisation.\n";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],3,"3 unverified organisations."; 
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],6,"6 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],1,"1 verified organisation (choco billy)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],0,"No verified transactions.";  
my $json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgId,
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
my $turtleValidatedId = $t->tx->res->json->{validatedOrganisationId};
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisations."; 
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],5,"5 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],2,"2 verified organisations (choco billy and turtle)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],1,"1 verified transaction.";  

print "test 17 - Logout Admin\n";
$t->post_ok('/logout')
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
$t->post_ok('/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);


print "test 19 - Attempt to merge own unvalidated organisation with validated one and fails.\n";
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgIdPartial,
  validatedOrganisationId => $turtleValidatedId,
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/You are not an admin/i);

print "test 20 - Logout Choco Billy\n";
$t->post_ok('/logout')
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
$t->post_ok('/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);


print "test 22 - JSON is missing.\n";
$t->post_ok('/admin-merge' => json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/JSON is missing/i);


print "test 23 - unvalidatedOrganisationId missing.\n";
$json = {
  validatedOrganisationId => $turtleValidatedId,
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/unvalidatedOrganisationId is missing/i);


print "test 24 - unvalidatedOrganisationId not number.\n";
$json = {
  unvalidatedOrganisationId => "ABC",
  validatedOrganisationId => $turtleValidatedId,
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/unvalidatedOrganisationId does not look like a number/i);


print "test 25 - validatedOrganisationId missing.\n";
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgIdPartial,
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/validatedOrganisationId is missing/i);


print "test 26 - validatedOrganisationId not number.\n";
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgIdPartial,
  validatedOrganisationId => "ABC",
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/validatedOrganisationId does not look like a number/i);


print "test 27 - unvalidatedOrganisationId does not exist.\n";
my ($maxPendingId) = $t->app->db->selectrow_array("SELECT MAX(PendingOrganisationId) FROM PendingOrganisations", undef,());
$json = {
  unvalidatedOrganisationId => ($maxPendingId + 1),
  validatedOrganisationId => $turtleValidatedId,
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/unvalidatedOrganisationId does not exist in the database/i);


print "test 28 - validatedOrganisationId does not exist.\n";
my ($maxId) = $t->app->db->selectrow_array("SELECT MAX(OrganisationalId) FROM Organisations", undef,());
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgIdPartial,
  validatedOrganisationId => ($maxId + 1),
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/validatedOrganisationId does not exist in the database/i);


my ($name, $fullAddress, $postCode) = $t->app->db->selectrow_array("SELECT Name, FullAddress, PostCode FROM Organisations WHERE OrganisationalId = ?", undef, ($turtleValidatedId));

print "test 29 - valid merge.\n";
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],2,"2 unverified organisations."; 
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],5,"5 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],2,"2 verified organisations (choco billy and turtle)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],1,"1 verified transaction."; 
$json = {
  unvalidatedOrganisationId => $newPendingTurtleOrgIdPartial,
  validatedOrganisationId => $turtleValidatedId,
};
$t->post_ok('/admin-merge' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingOrganisations", undef, ())}[0],1,"1 unverified organisation." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM PendingTransactions", undef, ())}[0],3,"3 unverified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations", undef, ())}[0],2,"2 verified organisations (choco billy and turtle)" ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions", undef, ())}[0],3,"3 verified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Transactions WHERE SellerOrganisationId_FK = ?", undef, ($turtleValidatedId))}[0],3,"3 verified transactions." ;
is @{$t->app->db->selectrow_arrayref("SELECT COUNT(*) FROM Organisations WHERE OrganisationalId = ? AND Name = ? AND FullAddress = ? AND PostCode = ?", undef, ($turtleValidatedId, $name, $fullAddress, $postCode))}[0],1,"Turtle exists with all orginal values.";

done_testing();