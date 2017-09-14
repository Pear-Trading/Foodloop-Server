use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;
my $dtf = $schema->storage->datetime_parser;

my $org_result = $schema->resultset('Organisation')->find({ name => 'Test Org' })->entity;
my $user_result = $schema->resultset('User')->find({ email => 'test1@example.com' })->entity;

my $session_key = $framework->login({
  email    => 'test1@example.com',
  password => 'abc123',
});

$t->app->schema->resultset('Leaderboard')->create_new( 'monthly_total', DateTime->now->truncate(to => 'month' )->subtract( months => 1) );

$t->post_ok('/api/stats' => json => { session_key => $session_key } )
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/today_sum', 0)
  ->json_is('/today_count', 0)
  ->json_is('/week_sum', 0)
  ->json_is('/week_count', 0)
  ->json_is('/month_sum', 0)
  ->json_is('/month_count', 0)
  ->json_is('/user_sum', 0)
  ->json_is('/user_count', 0)
  ->json_is('/global_sum', 0)
  ->json_is('/global_count', 0);

for ( 1 .. 10 ) {
  $user_result->create_related( 'purchases', {
    seller_id => $org_result->id,
    value => $_ * 100000,
    proof_image => 'a',
  });
}

for ( 11 .. 20 ) {
  $user_result->create_related( 'purchases', {
    seller_id => $org_result->id,
    value => $_ * 100000,
    proof_image => 'a',
    purchase_time => $dtf->format_datetime(DateTime->today()->subtract( days => 5 )),
  });
}

for ( 21 .. 30 ) {
  $user_result->create_related( 'purchases', {
    seller_id => $org_result->id,
    value => $_ * 100000,
    proof_image => 'a',
    purchase_time => $dtf->format_datetime(DateTime->today()->subtract( days => 25 )),
  });
}

for ( 31 .. 40 ) {
  $user_result->create_related( 'purchases', {
    seller_id => $org_result->id,
    value => $_ * 100000,
    proof_image => 'a',
    purchase_time => $dtf->format_datetime(DateTime->today()->subtract( days => 50 )),
  });
}

for ( 41 .. 50 ) {
  $org_result->create_related( 'purchases', {
    seller_id => $org_result->id,
    value => $_ * 100000,
    proof_image => 'a',
    purchase_time => $dtf->format_datetime(DateTime->today()->subtract( days => 50 )),
  });
}

is $user_result->purchases->search({
  purchase_time => {
    -between => [
      $dtf->format_datetime(DateTime->today()),
      $dtf->format_datetime(DateTime->today()->add( days => 1 )),
    ],
  },
})->get_column('value')->sum, 5500000, 'Got correct sum';
is $user_result->purchases->today_rs->get_column('value')->sum, 5500000, 'Got correct sum through rs';

$t->post_ok('/api/stats' => json => { session_key => $session_key } )
  ->status_is(200)
  ->json_is('/success', Mojo::JSON->true)
  ->json_is('/today_sum', 55)
  ->json_is('/today_count', 10)
  ->json_is('/week_sum', 155)
  ->json_is('/week_count', 10)
  ->json_is('/month_sum', 410)
  ->json_is('/month_count', 20)
  ->json_is('/user_sum', 820)
  ->json_is('/user_count', 40)
  ->json_is('/global_sum', 1275)
  ->json_is('/global_count', 50);

done_testing;
