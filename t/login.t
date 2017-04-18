use Mojo::Base -strict;

use File::Temp;
use Test::More;
use Test::Mojo;
use Mojo::JSON;
use Time::Fake;

my $file = File::Temp->new;

print $file <<'END';
{
  dsn => "dbi:SQLite::memory:",
  user => undef,
  pass => undef,
}
END
$file->seek( 0, SEEK_END );

$ENV{MOJO_CONFIG} = $file->filename;

my $t = Test::Mojo->new('Pear::LocalLoop');
my $schema = $t->app->schema;
$schema->deploy;

$schema->resultset('AgeRange')->populate([
  [ qw/ agerangestring / ],
  [ '20-35' ],
  [ '35-50' ],
  [ '50+' ],
]);

$schema->resultset('AccountToken')->create({
  accounttokenname => 'a',
});

my $accountToken = 'a';

my $sessionTimeSeconds = 60 * 60 * 24 * 7; #1 week.
my $sessionTokenJsonName = 'session_key';
my $sessionExpiresJsonName = 'sessionExpires';

my $location_is = sub {
  my ($t, $value, $desc) = @_;
  $desc ||= "Location: $value";
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return $t->success(is($t->tx->res->headers->location, $value, $desc));
};

#This depends on "register.t" working

#Valid customer, this also tests that redirects are disabled for register.
my $email = 'rufus@shinra.energy';
my $password = 'MakoGold';
my $testJson = {
  'usertype' => 'customer', 
  'token' => $accountToken, 
  'username' =>  'RufusShinra', 
  'email' => $email, 
  'postcode' => 'LA1 1AA', 
  'password' => $password, 
  'age' => '20-35'
};
$t->post_ok('/api/register' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true);

#Test login, this also checks that redirects are disabled for login when logged out.
$testJson = {
  'email' => $email,
  'password' => $password,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has("/$sessionTokenJsonName");


#Does login/logout work with a cookie based session.
print "test 5 - Logout (cookies)\n";
$t->post_ok('/api/logout')
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->content_like(qr/you were successfully logged out/i);

$t->reset_session;

#Login.
print "test 6 - Login (json)\n";
$testJson = {
  'email' => $email,
  'password' => $password,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has("/$sessionTokenJsonName")
  ->json_has("/$sessionExpiresJsonName");

my $sessionJsonTest = $t->tx->res->json;
my $expires = $sessionJsonTest->{$sessionExpiresJsonName};
my $sessionToken = $sessionJsonTest->{$sessionTokenJsonName};

#Reset the current state so you are still logged in but there are no cookies.
$t->reset_session;

#Redirect, as no cookies are set
print "test 7 - Login, no cookies or json redirect to login\n";
$t->get_ok('/api/')
  ->status_is(303)
  ->$location_is('/api/login');

print "test 8 - Login, no redirect on login paths (json)\n";
$t->get_ok('/api/' => json => {$sessionTokenJsonName => $sessionToken})
  ->status_is(200);

#No token send so redirect
print "test 9 - Logout, no cookies or json\n";
$t->post_ok('/api/logout')
  ->status_is(303)
  ->$location_is('/api/login');

#Token sent logout
print "test 10 - Logout, (json)\n";
$t->post_ok('/api/logout' => json => {$sessionTokenJsonName => $sessionToken})
  ->status_is(200);

#Send logged out expired token, 
print "test 11 - Logout,expired session redirect (json)\n";
$t->post_ok('/api/logout' => json => {$sessionTokenJsonName => $sessionToken})
  ->status_is(303)
  ->$location_is('/api/login');

$t->reset_session;

#TODO it's difficult to test cookies as they automatically get removed.

#Login.
print "test 12 - Login test with fake time (json)\n";
$testJson = {
  'email' => $email,
  'password' => $password,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has("/$sessionTokenJsonName")
  ->json_has("/$sessionExpiresJsonName");

$sessionJsonTest = $t->tx->res->json;
$expires = $sessionJsonTest->{$sessionExpiresJsonName};
$sessionToken = $sessionJsonTest->{$sessionTokenJsonName};

#Clear cookies
$t->reset_session;

#Offset time 
Time::Fake->offset("+".($sessionTimeSeconds * 2)."s");

#Send time expired token, 
print "test 13 - Fake time expired session redirect (json)\n";
$t->post_ok('/api/logout' => json => {$sessionTokenJsonName => $sessionToken})
  ->status_is(303)
  ->$location_is('/api/login');

Time::Fake->reset();

$t->reset_session;

#Attempt to logout without any session
# This is different from the one above as it's has no state.
print "test 14 - Logout, no session\n";
$t->post_ok('/api/logout')
  ->status_is(303)
  ->$location_is('/api/login');

#Clear the session state
$t->reset_session;

#Not logged in, redirect to login.
print "test 15 - Not logged in, get request redirect to login\n";
$t->get_ok('/api/')
  ->status_is(303)
  ->$location_is('/api/login');

$t->reset_session;

#Not logged in, redirect to login.
print "test 16 - Not logged in, get request one redirection is ok.\n";
$t->ua->max_redirects(1);
$t->get_ok('/api/')
  ->status_is(200);
$t->ua->max_redirects(0);

$t->reset_session;

#Not logged in, redirect to login.
print "test 17 - Not logged in, post request redirect to login\n";
$t->post_ok('/api/')
  ->status_is(303)
  ->$location_is('/api/login');

$t->reset_session;

#Not logged in, redirect to login.
print "test 18 - Not logged in, post request one redirection is ok.\n";
$t->ua->max_redirects(1);
$t->post_ok('/api/')
  ->status_is(200);
$t->ua->max_redirects(0);

$t->reset_session;

#Here on is just input params checking, no session testing.

#Test no JSON sent.
print "test 19 - No JSON sent.\n";
$t->post_ok('/api/login')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/No json sent/i);

$t->reset_session;

#Test no email sent
print "test 20 - Email missing\n";
$testJson = {
  'password' => $password,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/No email sent/i);

$t->reset_session;

#Invalid email
print "test 21 - Invalid email\n";
$testJson = {
  'email' => ($email . '@'),
  'password' => $password,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/email is invalid/i);

$t->reset_session;

#Test no password sent
print "test 22 - No password sent.\n";
$testJson = {
  'email' => $email,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/No password sent/i);

$t->reset_session;

#Email does not exist
print "test 23 - Email does not exist in the database\n";
$testJson = {
  'email' => 'heidegger@shinra.energy',
  'password' => $password,
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/Email or password is invalid/i);

$t->reset_session;

#Password is wrong
print "test 24 - Password is wrong\n";
$testJson = {
  'email' => $email,
  'password' => ($password . 'MoreText'),
};
$t->post_ok('/api/login' => json => $testJson)
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->content_like(qr/Email or password is invalid/i);

$t->reset_session;



#$testJson = {
#  'email' => $email,
#  'password' => $password,
#};
#$t->post_ok('/api/login' => json => $testJson)
#  ->status_is(200)
#  ->json_is('/success', Mojo::JSON->true);


#TODO expire session.


done_testing();
