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

set_absolute_time('2018-01-08T00:00:00Z');

my $start = DateTime->today->subtract( hours => 12 );

# create 40 days worth of data
for my $count ( 0 .. 40 ) {
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

$t->post_ok('/api/stats/customer' => json => {
    session_key => $session_key,
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/weeks', {
    first => 17,
    second => 20,
    max => 21,
    sum => 118,
    count => 6,
    })
  ->json_is('/sectors', {
    sectors => ['A'],
    purchases => [118],
  })
  ->json_is('/data', {
    cat_total => {
      Uncategorised => 810,
    },
    categories => {
      "2017-12-11" => [{
        days => "2017-12-11",
        value => 210,
        category => 'Uncategorised',
      }],
      "2017-12-18" => [{
        days => "2017-12-18",
        value => 200,
        category => 'Uncategorised',
      }],
      "2017-12-25" => [{
        days => "2017-12-25",
        value => 210,
        category => 'Uncategorised',
      }],
      "2018-01-01" => [{
        days => "2018-01-01",
        value => 190,
        category => 'Uncategorised',
      }],
    },
    cat_total => {
      Uncategorised => 810,
    },
    essentials => {
      purchase_no_essential_total => 0,
      purchase_no_total => 118,
    },
  })->or($framework->dump_error);

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
