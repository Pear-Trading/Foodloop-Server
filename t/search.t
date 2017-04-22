use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;
my $dump_error = sub { diag $t->tx->res->to_string };

my @account_tokens = ('a', 'b');
$schema->resultset('AccountToken')->populate([
  [ qw/ name / ],
  map { [ $_ ] } @account_tokens,
]);

$schema->resultset('Organisation')->populate([
  [ qw/ name street_name town postcode / ],
  [ "Avanti Bar & Restaurant", "57 Main St", "Kirkby Lonsdale", "LA6 2AH" ],
  [ "Full House Noodle Bar", "21 Common Garden St", "Lancaster", "LA1 1XD" ],
  [ "The Quay's Fishbar", "1 Adcliffe Rd", "Lancaster", "LA1 1SS" ],
  [ "Dan's Fishop", "56 North Rd", "Lancaster", "LA1 1LT" ],
  [ "Hodgeson's Chippy", "96 Prospect St", "Lancaster", "LA1 3BH" ],
]);

#test with a customer.
print "test 1 - Create customer user account (Rufus)\n";
my $emailRufus = 'rufus@shinra.energy';
my $passwordRufus = 'MakoGold';
my $testJson = {
  'usertype' => 'customer', 
  'token' => shift(@account_tokens), 
  'name' =>  'RufusShinra', 
  'email' => $emailRufus, 
  'postcode' => 'RG26 5NU', 
  'password' => $passwordRufus, 
  'age_range' => 1
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)->or($dump_error)
  ->json_is('/success', Mojo::JSON->true);

#test with an organisation.
print "test 2 - Create organisation user account (Choco Billy)\n";
my $emailBilly = 'choco.billy@chocofarm.org';
my $passwordBilly = 'Choco';
$testJson = {
  'usertype' => 'organisation', 
  'token' => shift(@account_tokens), 
  'name' =>  'ChocoBillysGreens', 
  'email' => $emailBilly, 
  'postcode' => 'LA1 1HT', 
  'password' => $passwordBilly, 
  'street_name' => 'Market St',
  'town' => 'Lancaster',
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200) 
  ->json_is('/success', Mojo::JSON->true);

my $session_key;

sub login_rufus {
  $testJson = {
    'email' => $emailRufus,
    'password' => $passwordRufus,
  };
  $t->post_ok('/api/login' => json => $testJson)
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true);
  $session_key = $t->tx->res->json('/session_key');
};

sub login_billy {
  $testJson = {
    'email' => $emailBilly,
    'password' => $passwordBilly,
  };
  $t->post_ok('/api/login' => json => $testJson)
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true);
  $session_key = $t->tx->res->json('/session_key');
};

sub log_out{
  $t->post_ok('/api/logout', json => { session_key => $session_key })
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true);
}


######################################################

#Login as Rufus (customer)

print "test 3 - Login - Rufus (cookies, customer)\n";
login_rufus();

print "test 4 - Added something containing 'fish'\n";
my $json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => 'Shoreway Fisheries',
  street_name => "2 James St",
  town => "Lancaster",
  postcode => "LA1 1UP",
  session_key => $session_key,
};
my $upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 5 - Logout Rufus \n";
log_out();

#End of Rufus (customer)

######################################################

#Login as Choco billy (organisation)

print "test 6 - Login - Choco billy (cookies, organisation)\n";
login_billy();

print "test 7 - Added something containing 'bar'\n";
$json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => 'The Palatine Bar',
  street_name => "The Crescent",
  town => "Morecambe",
  postcode => "LA4 5BZ",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 8 - Added another thing containing 'bar'\n";
$json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => 'The Sun Hotel & Bar',
  street_name => "63-65 Church Street",
  town => "Lancaster",
  postcode => "LA1 1ET",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 9 - Logout Choco billy \n";
log_out();

#End of Choco billy (organisation)

######################################################

#Login as Rufus (customer)

print "test 10 - Login - Rufus (cookies, customer)\n";
login_rufus();

sub check_vars{
  my ($searchTerm, $numValidated, $numUnvalidated) = @_;

  $t->post_ok('/api/search' => json => {
      search_name => $searchTerm,
      session_key => $session_key,
    })
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true)
    ->json_has("unvalidated")
    ->json_has("validated");

  my $sessionJsonTest = $t->tx->res->json;
  my $validated = $sessionJsonTest->{validated};  
  my $unvalidated = $sessionJsonTest->{unvalidated};

  my $validSize = scalar @$validated;
  my $unvalidSize = scalar @$unvalidated;

  is $validSize,$numValidated,"validated returned - " . $searchTerm;
  is $unvalidSize,$numUnvalidated,"unvalidated returned - " . $searchTerm;
  
};

print "test 11 - search blank\n";
check_vars(" ", 5, 1);

print "test 12 - Testing expected values with 'booths'\n";
#Expect 0 validated and 0 unvalidated with "booths".
check_vars("booths", 0, 0);

print "test 13 - Testing expected values with 'chip'\n";
#Expect 1 validated and 0 unvalidated with "chip".
check_vars("chip", 1, 0);

print "test 14 - Testing expected values with 'fish, with one unvalidated organisation'\n";
#Expect 2 validated and 1 unvalidated with "fish".
check_vars("fish", 2, 1);

print "test 15 - Testing expected values with 'bar'\n";
#Expect 3 validated and 0 unvalidated with "bar".
check_vars("bar", 3, 0);

print "test 16 - Logout Rufus \n";
log_out();

#End of Rufus (customer)

######################################################

#Login as Choco billy (organisation)

print "test 17 - Login - Choco billy (cookies, organisation)\n";
login_billy();

print "test 18 - Testing expected values with 'booths'\n";
#Expect 0 validated and 0 unvalidated with "booths".
check_vars("booths", 0, 0);

print "test 19 - Testing expected values with 'chip'\n";
#Expect 1 validated and 0 unvalidated with "chip".
check_vars("chip", 1, 0);

print "test 20 - Testing expected values with 'fish'\n";
#Expect 2 validated and 0 unvalidated with "fish".
check_vars("fish", 2, 0);

print "test 21 - Testing expected values with 'bar', with two unvalidated organisations\n";
#Expect 3 validated and 2 unvalidated with "bar".
check_vars("bar", 3, 2);

print "test 22 - Logout Choco billy \n";
log_out();


done_testing();
