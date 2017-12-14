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

$t->post_ok('/api/v1/customer/graphs' => json => {
    session_key => $session_key,
    graph => 'total_last_week',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $t->app->format_iso_datetime(
    $start->clone->subtract( days => $_ )->subtract( hours => 12 )
    ) } reverse ( 0 .. 6 ) ],
    bounds => {
      min => $t->app->format_iso_datetime($start->clone->subtract( days => 6 )->subtract( hours => 12 ) ),
      max => $t->app->format_iso_datetime($start->clone->add( hours => 12 )),
    },
    data => [ 20, 40, 20, 30, 30, 40, 10 ],
  });

$t->post_ok('/api/v1/customer/graphs' => json => {
    session_key => $session_key,
    graph => 'avg_spend_last_week',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $t->app->format_iso_datetime(
    $start->clone->subtract( days => $_ )->subtract( hours => 12 )
    ) } reverse ( 0 .. 29 ) ],
    bounds => {
      min => $t->app->format_iso_datetime($start->clone->subtract( days => 6 )->subtract( hours => 12 ) ),
      max => $t->app->format_iso_datetime($start->clone->add( hours => 12 )),
    },
    data => [ 10, 10, 10, 10, 10, 10, 10 ],
  });

$t->post_ok('/api/v1/customer/graphs' => json => {
    session_key => $session_key,
    graph => 'total_last_month',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $t->app->format_iso_datetime(
    $start->clone->subtract( days => $_ )->subtract( hours => 12 )
    ) } reverse ( 0 .. 29 ) ],
    bounds => {
      min => $t->app->format_iso_datetime($start->clone->subtract( days => 29 )->subtract( hours => 12 ) ),
      max => $t->app->format_iso_datetime($start->clone->add( hours => 12 )),
    },
    data => [ 40, 20, 30, 30, 40, 10, 40, 30, 30, 20, 40, 20, 40, 20, 30, 30, 40, 10, 40, 30, 30, 20, 40, 20, 40, 20, 30, 30, 40, 10 ],
  });

$t->post_ok('/api/v1/customer/graphs' => json => {
    session_key => $session_key,
    graph => 'avg_spend_last_month',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/graph', {
    labels => [ map { $t->app->format_iso_datetime(
    $start->clone->subtract( days => $_ )->subtract( hours => 12 )
    ) } reverse ( 0 .. 29 ) ],
    bounds => {
      min => $t->app->format_iso_datetime($start->clone->subtract( days => 29 )->subtract( hours => 12 ) ),
      max => $t->app->format_iso_datetime($start->clone->add( hours => 12 )),
    },
    data => [ 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ],
  });

$framework->logout( $session_key );

$session_key = $framework->login({
  email => 'org@example.com',
  password => 'abc123',
});

$t->post_ok('/api/v1/customer/graphs' => json => {
    session_key => $session_key,
    graph => 'avg_spend_last_week',
  })
  ->status_is(403)
  ->json_is('/success', Mojo::JSON->false)
  ->json_is('/error', 'user_not_cust');


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
