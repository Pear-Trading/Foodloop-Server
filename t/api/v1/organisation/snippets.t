use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../../../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;

my $start = DateTime->today->subtract( hours => 12 );

# create 30 days worth of data
for my $count ( 0 .. 29 ) {
  my $trans_day = $start->clone->subtract( days => $count );

  create_random_transaction( 'test1@example.com', $trans_day );
  if ( $count % 2 ) {
    create_random_transaction( 'test2@example.com', $trans_day );
  }
  if ( $count % 3 ) {
    create_random_transaction( 'test3@example.com', $trans_day );
  }
  if ( $count % 4 ) {
    create_random_transaction( 'test4@example.com', $trans_day );
  }
}

my $session_key = $framework->login({
  email => 'org@example.com',
  password => 'abc123',
});

$t->post_ok('/api/v1/organisation/snippets' => json => {
    session_key => $session_key,
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/snippets', {
      this_month_sales_count => 87,
      this_month_sales_total => 870,
      this_week_sales_count  => 19,
      this_week_sales_total  => 190,
      today_sales_count      => 0,
      today_sales_total      => 0,
      all_sales_count      => 87,
      all_sales_total      => 870,
      this_month_purchases_count => 0,
      this_month_purchases_total => 0,
      this_week_purchases_count  => 0,
      this_week_purchases_total  => 0,
      today_purchases_count      => 0,
      today_purchases_total      => 0,
      all_purchases_count      => 0,
      all_purchases_total      => 0,
  });

$framework->logout( $session_key );

$session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

sub create_random_transaction {
  my $buyer = shift;
  my $time = shift;

  my $buyer_result = $schema->resultset('User')->find({ email => $buyer })->entity;
  my $seller_result = $schema->resultset('Organisation')->find({ name => 'Test Org' })->entity;
  $schema->resultset('Transaction')->create({
    buyer => $buyer_result,
    seller => $seller_result,
    value => 10 * 100000,
    proof_image => 'a',
    purchase_time => $time,
  });
}

done_testing;
