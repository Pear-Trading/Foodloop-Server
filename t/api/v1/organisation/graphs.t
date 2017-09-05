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

$t->post_ok('/api/v1/organisation/graphs' => json => {
    session_key => $session_key,
    graph => 'customers_last_7_days',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $start->clone->subtract( days => $_ )->day_name } reverse ( 0 .. 6 ) ],
    data => [ 2, 4, 2, 3, 3, 4, 1 ],
  });

$t->post_ok('/api/v1/organisation/graphs' => json => {
    session_key => $session_key,
    graph => 'customers_last_30_days',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $start->clone->subtract( days => $_ )->day_name } reverse ( 0 .. 29 ) ],
    data => [ 4, 2, 3, 3, 4, 1, 4, 3, 3, 2, 4, 2, 4, 2, 3, 3, 4, 1, 4, 3, 3, 2, 4, 2, 4, 2, 3, 3, 4, 1 ],
  });

$t->post_ok('/api/v1/organisation/graphs' => json => {
    session_key => $session_key,
    graph => 'sales_last_7_days',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $start->clone->subtract( days => $_ )->day_name } reverse ( 0 .. 6 ) ],
    data => [ 20, 40, 20, 30, 30, 40, 10 ],
  });

$t->post_ok('/api/v1/organisation/graphs' => json => {
    session_key => $session_key,
    graph => 'sales_last_30_days',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $start->clone->subtract( days => $_ )->day_name } reverse ( 0 .. 29 ) ],
    data => [ 40, 20, 30, 30, 40, 10, 40, 30, 30, 20, 40, 20, 40, 20, 30, 30, 40, 10, 40, 30, 30, 20, 40, 20, 40, 20, 30, 30, 40, 10 ],
  });

$framework->logout( $session_key );

$session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

$t->post_ok('/api/v1/organisation/graphs' => json => {
    session_key => $session_key,
    graph => 'customers_last_7_days',
  })
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/error', 'user_not_org');


sub create_random_transaction {
  my $buyer = shift;
  my $time = shift;

  my $buyer_result = $schema->resultset('User')->find({ email => $buyer })->entity;
  my $seller_result = $schema->resultset('Organisation')->find({ name => 'Test Org' })->entity;
  $schema->resultset('Transaction')->create({
    buyer => $buyer_result,
    seller => $seller_result,
    value => 10,
    proof_image => 'a',
    purchase_time => $time,
  });
}

done_testing;
