use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;

my $user = {
  token        => 'a',
  full_name    => 'Test User',
  display_name => 'Test User',
  email        => 'test@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  age_range    => 1,
};

my $org = {
  token       => 'b',
  email       => 'test2@example.com',
  name        => 'Test Org',
  street_name => 'Test Street',
  town        => 'Lancaster',
  postcode    => 'LA1 1AA',
  password    => 'abc123',
};

$schema->resultset('AccountToken')->create({ name => $user->{token} });
$schema->resultset('AccountToken')->create({ name => $org->{token} });

$framework->register_customer($user);
$framework->register_organisation($org);

my $org_result = $schema->resultset('Organisation')->find({ name => $org->{name} });
my $user_result = $schema->resultset('User')->find({ email => $user->{email} });

for ( 1 .. 10 ) {
  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => $_,
    proof_image => 'a',
  });
}

my $dtf = $schema->storage->datetime_parser;
is $user_result->transactions->search({
  submitted_at => {
    -between => [
      $dtf->format_datetime(DateTime->today()),
      $dtf->format_datetime(DateTime->today()->add( days => 1 )),
    ],
  },
})->get_column('value')->sum, 55, 'Got correct sum';
is $user_result->transactions->today_rs->get_column('value')->sum, 55, 'Got correct sum through rs';
is $schema->resultset('Transaction')->today_for_user($user_result)->get_column('value')->sum, 55, 'Got correct sum through rs';

my $session_key = $framework->login({
  email    => $user->{email},
  password => $user->{password},
});

$t->post_ok('/api/stats' => json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/today_sum', 55)
  ->json_is('/today_count', 10);

done_testing;
