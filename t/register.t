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

#Variables to be used for uniqueness when testing.
my @names = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');
my @emails = ('a@a.com', 'b@a.com', 'c@a.com', 'd@a.com', 'e@a.com', 'f@a.com', 'g@a.com', 'h@a.com', 'i@a.com', 'j@a.com', 'k@a.com', 'l@a.com', 'm@a.com', 'n@a.com', 'o@a.com', 'p@a.com', 'q@a.com', 'r@a.com', 's@a.com', 't@a.com', 'u@a.com', 'v@a.com', 'w@a.com', 'x@a.com', 'y@a.com', 'z@a.com');
my @tokens =  ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');
my $tokenStatement = $dbh->prepare('INSERT INTO AccountTokens (AccountTokenName) VALUES (?)');
foreach (@tokens){
  my $rowsAdded = $tokenStatement->execute($_);
}

#No JSON sent
print "test1\n\n";
$t->post_ok('/register')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no json sent/i);

#Empty JSON
print "test2\n\n";
my $testJson = {};
$t->post_ok('/register' => json => $testJson)
  ->json_is('/success', Mojo::JSON->false);

#token missing JSON
print "test3\n\n";
my $testJson = {
  'usertype' => 'customer',
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no token sent/i);


#Not valid token.
print "test4\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => ' ',
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/token/i)
  ->content_like(qr/invalid/i);

#username missing JSON
print "test5\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no username sent/i);


#Blank username
print "test6\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens), 
  'username' => '', 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/blank/i)
  ->content_like(qr/username/i);

#Not alpha numeric chars e.g. !
print "test7\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens), 
  'username' =>  'asa!', 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/username/i);

my $usernameToReuse =  shift(@names);
my $emailToReuse =  shift(@emails);

#Valid customer
print "test8\n\n";
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  $usernameToReuse, 
  'email' => $emailToReuse, 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#Valid customer2
print "test9\n\n";
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);

#Valid customer3
print "test10\n\n";
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '20-35'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);

#Username exists
print "test11\n\n";
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' => $usernameToReuse, 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(403) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/exists/i);

#email missing JSON
print "test12\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no email sent/i);

#invalid email 1 
print "test13\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => 'dfsd@.com', 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/invalid/i);

#invalid email 2
print "test14\n\n";
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => 'dfsd@com', 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/invalid/i);

#Email exists
print "test15\n\n";
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => $emailToReuse, 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => '35-50'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(403) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email/i)
  ->content_like(qr/exists/i);

#postcode missing JSON
print "test16\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no postcode sent/i);

#TODO validate postcode

#password missing JSON
print "test17\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no password sent/i);

#TODO enforce password complexity requirements.

#usertype missing JSON
print "test18\n\n";
my $testJson = {
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
  'age' => '50+'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no usertype sent/i);

#Invalid user type
print "test19\n\n";
my $testJson = {
  'usertype' => 'organisation1', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'fulladdress' => 'mary lane testing....'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/usertype/i)
  ->content_like(qr/invalid/i);


#age missing JSON
print "test20\n\n";
my $testJson = {
  'usertype' => 'customer',
  'token' => shift(@tokens),
  'username' => shift(@names),
  'email' => shift(@emails),
  'postcode' => 'LA1 1AA',
  'password' => 'Meh',
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no age sent/i);

#Age is invalid
print "test21\n\n";
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'age' => 'invalid'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400) 
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/age/i)
  ->content_like(qr/invalid/i);

#full address missing JSON
print "test22\n\n";
my $testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/no fulladdress sent/i);

#TODO Validation of full address

#Organisation valid
print "test23\n\n";
my $testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@tokens), 
  'username' =>  shift(@names), 
  'email' => shift(@emails), 
  'postcode' => 'LA1 1AA', 
  'password' => 'Meh', 
  'fulladdress' => 'mary lane testing....'
};
$t->post_ok('/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);


#No JSON sent
#print "test14\n\n";
#my $testJson = {
#  'usertype' => 'customer',
#  'token' => shift(@tokens),
#  'username' => shift(@names),
#  'email' => shift(@emails),
#  'postcode' => 'LA1 1AA',
#  'password' => 'Meh',
#  'age' => '50+'
#};
#$t->post_ok('/register' => json => $testJson)
#  ->status_is(401)->or(sub{ diag $t->tx->res->body})
#  ->json_is('/success', Mojo::JSON->false)
#  ->content_like(qr/token/i);


done_testing();
