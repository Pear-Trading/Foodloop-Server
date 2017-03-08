use Test::More;
use Test::Mojo;
use Mojo::JSON qw(encode_json);;
use Time::Fake;
use Data::Dumper;
use DateTime;

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

my $dateTimeNow = DateTime->now();

#Plus 2 days so you cannot have a bug where it goes past midnight when you run the test, plus one hour to remove odd error
my $dateTimeInitial = $dateTimeNow->clone()->truncate(to => day)->add(days => 2, hours => 1);
my $dateTimePlusTwoDays = $dateTimeInitial->clone()->add(days => 2);
my $dateTimePlusOneMonth = $dateTimeInitial->clone()->add(months => 1);
my $dateTimePlusOneYear = $dateTimeInitial->clone()->add(years => 1, days => 1);

my $dateTimePlusThreeDays = $dateTimeInitial->clone()->add(days => 3);
my $dateTimePlusOneMonthMinusOneDay = $dateTimePlusOneMonth->clone()->subtract(days => 1);

#Clock skew second diffs
my $dateTimeInitialDiff = $dateTimeInitial->delta_ms($dateTimeNow)->delta_minutes() * 60;
my $dateTimePlusTwoDaysSecondsDiff = $dateTimePlusTwoDays->delta_ms($dateTimeNow)->delta_minutes() * 60;
my $dateTimePlusOneMonthSecondsDiff = $dateTimePlusOneMonth->delta_ms($dateTimeNow)->delta_minutes() * 60;
my $dateTimePlusOneYearSecondsDiff = $dateTimePlusOneYear->delta_ms($dateTimeNow)->delta_minutes() * 60;

#Change to the initial time.
Time::Fake->offset("+" . $dateTimeInitialDiff . "s");

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

sub logout {
  $t->post_ok('/logout')
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true);
}

sub login_reno {
  $testJson = {
    'email' => $emailReno,
    'password' => $passwordReno,
  };
  $t->post_ok('/login' => json => $testJson)
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true);
}

sub login_chocobilly {
  $testJson = {
    'email' => $emailBilly,
    'password' => $passwordBilly,
  };
  $t->post_ok('/login' => json => $testJson)
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true);
}

sub login_admin {
  $testJson = {
    'email' => $emailAdmin,
    'password' => $passwordAdmin,
  };
  $t->post_ok('/login' => json => $testJson)
    ->status_is(200)
    ->json_is('/success', Mojo::JSON->true);
}

print "test 5 - Login non-admin Reno\n";
login_reno();


print "test 6 - Reno spends at Turtle\'s Paradise\n";
my $nameToTestTurtle = 'Turtle\'s Paradise';
$json = {
  microCurrencyValue => 10,
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
my $unvalidatedOrganisationId = $t->tx->res->json->{unvalidatedOrganisationId};

#Change to 2 days later
Time::Fake->offset("+" . $dateTimePlusTwoDaysSecondsDiff . "s");

print "test 7 - Reno spends at Turtle\'s Paradise, 2 days later, transaction 1/2\n";
$json = {
  microCurrencyValue => 20,
  transactionAdditionType => 2,
  addUnvalidatedId => $unvalidatedOrganisationId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 8 - Reno spends at Turtle\'s Paradise, 2 days later, transaction 2/2\n";
$json = {
  microCurrencyValue => 40,
  transactionAdditionType => 2,
  addUnvalidatedId => $unvalidatedOrganisationId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 9 - Logout non-admin Reno (time offset causes session to expire)\n";
logout();

#Change to 1 month later
Time::Fake->offset("+" . $dateTimePlusOneMonthSecondsDiff . "s");

print "test 10 - Login non-admin Reno\n";
login_reno();

print "test 11 - Reno spends at Turtle\'s Paradise, 1 month later\n";
$json = {
  microCurrencyValue => 80,
  transactionAdditionType => 2,
  addUnvalidatedId => $unvalidatedOrganisationId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 12 - Logout non-admin Reno\n";
logout();

#Change to 1 year (and a bit) later
Time::Fake->offset("+" . $dateTimePlusOneYearSecondsDiff . "s");

print "test 13 - Login non-admin Reno\n";
login_reno();

print "test 14 - Reno spends at Turtle\'s Paradise, 1 year later\n";
$json = {
  microCurrencyValue => 160,
  transactionAdditionType => 2,
  addUnvalidatedId => $unvalidatedOrganisationId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 15 - Logout non-admin Reno\n";
logout();

#Change to 2 days later
Time::Fake->offset("+" . $dateTimePlusTwoDaysSecondsDiff . "s");

print "test 16 - Login Admin\n";
login_admin();

print "test 17 - Admin approves Turtle\'s Paradise.\n";
$json = {
  unvalidatedOrganisationId => $unvalidatedOrganisationId,
};
$t->post_ok('/admin-approve' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);
my $validatedOrganisationId = $t->tx->res->json->{validatedOrganisationId};


print "test 18 - Logout Admin\n";
logout();

print "test 19 - Login non-admin Chocobilly\n";
login_chocobilly();

print "test 20 - Chocobilly spends at Turtle\'s Paradise, 2 days later\n";
#Added to test and see if the later values from different users merge together. They shouldn't
$json = {
  microCurrencyValue => 320,
  transactionAdditionType => 1,
  addValidatedId => $validatedOrganisationId,
};
my $upload = {json => Mojo::JSON::encode_json($json), file2 => {file => './t/test.jpg'}};
$t->post_ok('/upload' => form => $upload )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

print "test 21 - Logout non-admin Chocobilly\n";
logout();

#Change back to 1 year (and a bit) later
Time::Fake->offset("+" . $dateTimePlusOneYearSecondsDiff . "s");

##Actual testing from here onwards.

print "test 22 - Login non-admin Reno\n";
login_reno();


print "test 23 - No JSON\n";
$t->post_ok('/user-history')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/JSON is missing/i);

print "test 24 - retrieveType is missing\n";
$json = {
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => $dateTimePlusThreeDays->month(), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/retrieveType is missing/i);

print "test 25 - retrieveType is not a number\n";
$json = {
  retrieveType => "A",
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => $dateTimePlusThreeDays->month(), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/retrieveType does not look like a number/i);

print "test 26 - retrieveType is not 1 or 2\n";
$json = {
  retrieveType => 0,
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => $dateTimePlusThreeDays->month(), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/retrieveType can only be 1 or 2./i);

#Single tests

print "test 27 - single date - dayNumber is missing\n";
$json = {
  retrieveType => 1,
  monthNumber => $dateTimePlusThreeDays->month(), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/dayNumber is missing./i);

print "test 28 - single date - dayNumber is not a number\n";
$json = {
  retrieveType => 1,
  dayNumber => "A", 
  monthNumber => $dateTimePlusThreeDays->month(), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/dayNumber does not look like a number./i);

print "test 29 - single date - monthNumber is missing\n";
$json = {
  retrieveType => 1,
  dayNumber => $dateTimePlusThreeDays->day(), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/monthNumber is missing./i);

print "test 30 - single date - monthNumber is not a number\n";
$json = {
  retrieveType => 1,
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => "ABC", 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/monthNumber does not look like a number./i);

print "test 31 - single date - year is missing\n";
$json = {
  retrieveType => 1,
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => $dateTimePlusThreeDays->month(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/year is missing./i);

print "test 32 - single date - year is not a number\n";
$json = {
  retrieveType => 1,
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => $dateTimePlusThreeDays->month(), 
  year => "I1", 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/year does not look like a number./i);

print "test 33 - Invalid date\n";
$json = {
  retrieveType => 1,
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => ($dateTimePlusThreeDays->month() + 13), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/date is invalid./i);

#Range tests.

print "test 34 - range date - startDayNumber is missing\n";
$json = {
  retrieveType => 2,
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/startDayNumber is missing./i);

print "test 35 - range date - startDayNumber is not a number\n";
$json = {
  retrieveType => 2,
  startDayNumber => "2ER",
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/startDayNumber does not look like a number./i);


print "test 36 - range date - startMonthNumber is missing\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/startMonthNumber is missing./i);

print "test 37 - range date - startMonthNumber is not a number\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => "Text",
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/startMonthNumber does not look like a number./i);

print "test 38 - range date - startYear is missing\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/startYear is missing./i);

print "test 39 - range date - startYear is not a number\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => "Years2",
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/startYear does not look like a number./i);

print "test 40 - Invalid start date\n";
$json = {
  retrieveType => 2,
  startDayNumber => ($dateTimeInitial->day() + 60),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/start date is invalid./i);

## Valid data testing.

print "test 41 - range date - endDayNumber is missing\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/endDayNumber is missing./i);

print "test 42 - range date - endDayNumber is not a number\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => "2EF",
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/endDayNumber does not look like a number./i);

print "test 43 - range date - endMonthNumber is missing\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/endMonthNumber is missing./i);

print "test 44 - range date - endMonthNumber is not a number\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => "A5G",
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/endMonthNumber does not look like a number./i);

print "test 43 - range date - endYear is missing\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/endYear is missing./i);

print "test 44 - range date - endYear is not a number\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => "ABC",
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/endYear does not look like a number./i);

print "test 40 - Invalid end date\n";
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => ($dateTimePlusOneYear->day() - 60),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/end date is invalid./i);


print "test 41 - Test single day with no transactions\n";
my $expectedReturnedStats = {};
$json = {
  retrieveType => 1,
  dayNumber => $dateTimePlusThreeDays->day(), 
  monthNumber => $dateTimePlusThreeDays->month(), 
  year => $dateTimePlusThreeDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/microCurencySpent')
  ->json_is('/microCurencySpent',$expectedReturnedStats);
my $spend = $t->tx->res->json->{microCurencySpent};
print Dumper($spend) . "\n";

print "test 42 - Test single day with one transaction\n";
$expectedReturnedStats = {};
$expectedReturnedStats->{$dateTimeInitial->year}{$dateTimeInitial->month}{$dateTimeInitial->day} = 10;
$json = {
  retrieveType => 1,
  dayNumber => $dateTimeInitial->day(), 
  monthNumber => $dateTimeInitial->month(), 
  year => $dateTimeInitial->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/microCurencySpent')
  ->json_is('/microCurencySpent',$expectedReturnedStats);
my $spend = $t->tx->res->json->{microCurencySpent};
print Dumper($spend) . "\n";

print "test 43 - Test single day with multiple transactions and user separateness\n";
$expectedReturnedStats = {};
$expectedReturnedStats->{$dateTimePlusTwoDays->year}{$dateTimePlusTwoDays->month}{$dateTimePlusTwoDays->day} = 60;
$json = {
  retrieveType => 1,
  dayNumber => $dateTimePlusTwoDays->day(), 
  monthNumber => $dateTimePlusTwoDays->month(), 
  year => $dateTimePlusTwoDays->year(), 
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/microCurencySpent')
  ->json_is('/microCurencySpent',$expectedReturnedStats);
my $spend = $t->tx->res->json->{microCurencySpent};
print Dumper($spend) . "\n";

print "test 44 - Test range with no transactions\n";
#Empty range
$expectedReturnedStats = {};
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimePlusThreeDays->day(),
  startMonthNumber => $dateTimePlusThreeDays->month(),
  startYear => $dateTimePlusThreeDays->year(),
  endDayNumber => $dateTimePlusOneMonthMinusOneDay->day(),
  endMonthNumber => $dateTimePlusOneMonthMinusOneDay->month(),
  endYear => $dateTimePlusOneMonthMinusOneDay->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/microCurencySpent')
  ->json_is('/microCurencySpent',$expectedReturnedStats);
my $spend = $t->tx->res->json->{microCurencySpent};
print Dumper($spend) . "\n";

print "test 45 - Test range with multiple very similar dated transactions (2 day window), test multiple transactions on a day and user separateness\n";
#Testing boundary condition one day before the next value.
$expectedReturnedStats = {};
$expectedReturnedStats->{$dateTimeInitial->year}{$dateTimeInitial->month}{$dateTimeInitial->day} = 10;
$expectedReturnedStats->{$dateTimePlusTwoDays->year}{$dateTimePlusTwoDays->month}{$dateTimePlusTwoDays->day} = 60;
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneMonthMinusOneDay->day(),
  endMonthNumber => $dateTimePlusOneMonthMinusOneDay->month(),
  endYear => $dateTimePlusOneMonthMinusOneDay->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/microCurencySpent')
  ->json_is('/microCurencySpent',$expectedReturnedStats);
my $spend = $t->tx->res->json->{microCurencySpent};
print Dumper($spend) . "\n";

print "test 46 - Test range with multiple transactions spread over a few days, a month and a year, as well as user separateness\n";
$expectedReturnedStats = {};
$expectedReturnedStats->{$dateTimeInitial->year}{$dateTimeInitial->month}{$dateTimeInitial->day} = 10;
$expectedReturnedStats->{$dateTimePlusTwoDays->year}{$dateTimePlusTwoDays->month}{$dateTimePlusTwoDays->day} = 60;
$expectedReturnedStats->{$dateTimePlusOneMonth->year}{$dateTimePlusOneMonth->month}{$dateTimePlusOneMonth->day} = 80;
$expectedReturnedStats->{$dateTimePlusOneYear->year}{$dateTimePlusOneYear->month}{$dateTimePlusOneYear->day} = 160;
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/microCurencySpent')
  ->json_is('/microCurencySpent',$expectedReturnedStats);
my $spend = $t->tx->res->json->{microCurencySpent};
print Dumper($spend) . "\n";

print "test 47 - Logout non-admin Reno\n";
logout();

print "test 48 - Login non-admin Chocobilly\n";
login_chocobilly();

print "test 49- Test user separateness under different user.\n";
$expectedReturnedStats = {};
$expectedReturnedStats->{$dateTimePlusTwoDays->year}{$dateTimePlusTwoDays->month}{$dateTimePlusTwoDays->day} = 320;
$json = {
  retrieveType => 2,
  startDayNumber => $dateTimeInitial->day(),
  startMonthNumber => $dateTimeInitial->month(),
  startYear => $dateTimeInitial->year(),
  endDayNumber => $dateTimePlusOneYear->day(),
  endMonthNumber => $dateTimePlusOneYear->month(),
  endYear => $dateTimePlusOneYear->year(),
};
$t->post_ok('/user-history' => json => $json)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/microCurencySpent')
  ->json_is('/microCurencySpent',$expectedReturnedStats);
my $spend = $t->tx->res->json->{microCurencySpent};
print Dumper($spend) . "\n";

print "test 50 - Logout non-admin Chocobilly\n";
logout();

done_testing();
