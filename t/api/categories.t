use Mojo::Base -strict;

BEGIN {
  use Test::MockTime qw/ set_absolute_time /;
}

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

$schema->resultset('Category')->create({
  id => 1,
  name => 'test',
});

set_absolute_time('2017-01-02T00:00:00Z');

my $start = DateTime->today->subtract( hours => 12 );

# create 40 days worth of data
for my $count ( 0 .. 28 ) {
  my $trans_day = $start->clone->subtract( days => $count );

  create_random_transaction( 'test1@example.com', $trans_day );
  if ( $count % 2 ) {
    create_random_transaction( 'test1@example.com', $trans_day );
  }
  if ( $count % 3 ) {
    create_random_transaction( 'test1@example.com', $trans_day );
  }
  if ( $count % 4 ) {
    create_random_transaction( 'test1@example.com', $trans_day );
  }
}

my $session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

$t->post_ok('/api/stats/category' => json => {
    session_key => $session_key,
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/data', {
    categories => {
      "2016-12-05" => [{
        days => "2016-12-05",
        value => 210,
        category => 1,
      }],
      "2016-12-12" => [{
        days => "2016-12-12",
        value => 200,
        category => 1,
      }],
      "2016-12-19" => [{
        days => "2016-12-19",
        value => 210,
        category => 1,
      }],
      "2016-12-26" => [{
        days => "2016-12-26",
        value => 190,
        category => 1,
      }],
    },
    essentials => {
      "2016-12-05" => {
        value => 210,
      },
      "2016-12-12" => {
        value => 200,
      },
      "2016-12-19" => {
        value => 210,
      },
      "2016-12-26" => {
        value => 190,
      },
    }
  })->or($framework->dump_error);

sub create_random_transaction {
  my $buyer = shift;
  my $time = shift;


  my $buyer_result = $schema->resultset('User')->find({ email => $buyer })->entity;
  my $seller_result = $schema->resultset('Organisation')->find({ name => 'Test Org' })->entity;
  my $test_transaction = $schema->resultset('Transaction')->create({
    buyer => $buyer_result,
    seller => $seller_result,
    value => 10 * 100000,
    proof_image => 'a',
    purchase_time => $time,
    essential => 1,
  });

  $schema->resultset('TransactionCategory')->create({
    category_id => 1,
    transaction_id => $test_transaction->id,
  });
}

done_testing;
