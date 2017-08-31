use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../etc",
);
$framework->install_fixtures('search');

my $t = $framework->framework;
my $schema = $t->app->schema;

#Login as customer
my $session_key = $framework->login({
  'email' => 'test1@example.com',
  'password' => 'abc123',
});

my $json;
my $upload;

$t->post_ok( '/api/upload', form => {
    json => Mojo::JSON::encode_json({
      transaction_value => 10,
      transaction_type => 3,
      organisation_name => 'Shoreway Fisheries',
      street_name => "2 James St",
      town => "Lancaster",
      postcode => "LA1 1UP",
      purchase_time => "2017-08-14T11:29:07.965+01:00",
      session_key => $session_key,
    }),
    file => { file => './t/test.jpg' },
  })
  ->status_is(200)
  ->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

$framework->logout( $session_key );

#End of Rufus (customer)

######################################################

#Login as Choco billy (organisation)

print "test 6 - Login - Choco billy (cookies, organisation)\n";
$session_key = $framework->login({
  'email' => 'org@example.com',
  'password' => 'abc123',
});

print "test 7 - Added something containing 'bar'\n";
$json = {
  transaction_value => 10,
  transaction_type => 3,
  organisation_name => 'The Palatine Bar',
  street_name => "The Crescent",
  town => "Morecambe",
  postcode => "LA4 5BZ",
  purchase_time => "2017-08-14T11:29:07.965+01:00",
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
  purchase_time => "2017-08-14T11:29:07.965+01:00",
  session_key => $session_key,
};
$upload = {json => Mojo::JSON::encode_json($json), file => {file => './t/test.jpg'}};
$t->post_ok('/api/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 9 - Logout Choco billy \n";
$framework->logout( $session_key );

$session_key = $framework->login({
  'email' => 'test1@example.com',
  'password' => 'abc123',
});

sub check_vars{
  my ($searchTerm, $numValidated, $numUnvalidated) = @_;

  $t->post_ok('/api/search' => json => {
      search_name => $searchTerm,
      session_key => $session_key,
    })
    ->status_is(200)
    ->or($framework->dump_error)
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
check_vars(" ", 6, 1);

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
$framework->logout( $session_key );

#End of Rufus (customer)

######################################################

#Login as Choco billy (organisation)

print "test 17 - Login - Choco billy (cookies, organisation)\n";
$session_key = $framework->login({
  'email' => 'org@example.com',
  'password' => 'abc123',
});

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
$framework->logout( $session_key );

done_testing();
