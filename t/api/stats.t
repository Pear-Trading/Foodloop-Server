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

set_absolute_time('2017-01-01T00:00:00Z');

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
    first => 2,
    second => 21,
    max => 22,
    sum => 118,
    count => 7,
    })
  ->or($framework->dump_error)
  ->json_is('/sectors', {
    sectors => ['A'],
    purchases => [118],
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
