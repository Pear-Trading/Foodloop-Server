use Test::More;
use Test::Mojo;
use Mojo::JSON;

use FindBin;

$ENV{MOJO_MODE} = 'development';
$ENV{MOJO_LOG_LEVEL} = 'debug';

require "$FindBin::Bin/../foodloopserver.pl";

my $t = Test::Mojo->new;

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
my @names = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n');
my @emails = ('a@a.com', 'b@a.com', 'c@a.com', 'd@a.com', 'e@a.com', 'f@a.com', 'g@a.com', 'h@a.com', 'i@a.com', 'j@a.com', 'k@a.com', 'l@a.com', 'm@a.com', 'n@a.com');
my @tokens = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n');
my $tokenStatement = $dbh->prepare('INSERT INTO Tokens (TokenName) VALUES (?)');
foreach (@tokens){
  my $rowsAdded = $tokenStatement->execute($_);
}


#Not valid token.
print "test1\n\n";
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
  ->status_is(401)->or(sub{ diag $t->tx->res->body})
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/token/i);

#Blank username
print "test2\n\n";
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
print "test3\n\n";
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
print "test4\n\n";
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
print "test5\n\n";
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
print "test6\n\n";
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
print "test7\n\n";
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

#invalid email 1 
print "test8\n\n";
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
print "test9\n\n";
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
print "test10\n\n";
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


#Age is invalid
print "test11\n\n";
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

#Organisation valid
print "test12\n\n";
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

#Invalid user type
print "test13\n\n";
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

done_testing();
