use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../../etc",
);
$framework->install_fixtures('full');
my $t = $framework->framework;
my $schema = $t->app->schema;

my $dt_today = DateTime->today;
my $dt_start = $dt_today->clone->subtract( 'minutes' => 30 );

use Devel::Dwarn;

my $session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

sub create_transaction {
  my ( $value, $time ) = @_;
  $t->ua->post('/api/upload' => json => {
    transaction_value => $value,
    transaction_type => 1,
    purchase_time => $time,
    organisation_id => 1,
    session_key => $session_key,
  });
}

my $expected_days = {};
my $expected_hours = {};

sub increment_day {
  my ( $value, $day, $distance ) = @_;
  $value *= 100000;
  $distance //= 845;
  $expected_days->{$day} = {
    quantised         => $day,
    sum_value         => ($expected_days->{$day}->{sum_value} || 0) + $value,
    sum_distance      => ($expected_days->{$day}->{sum_distance} || 0) + $distance,
    count             => ++$expected_days->{$day}->{count},
  };
}

sub increment_hour {
  my ( $value, $day, $distance ) = @_;
  $value *= 100000;
  $distance //= 845;
  $expected_hours->{$day} = {
    quantised         => $day,
    sum_value         => ($expected_hours->{$day}->{sum_value} || 0) + $value,
    sum_distance      => ($expected_hours->{$day}->{sum_distance} || 0) + $distance,
    count             => ++$expected_hours->{$day}->{count},
  };
}

for my $i ( 0 .. 48 ) {
  my $dt = $dt_start->clone->subtract( 'minutes' => 60 * $i );
  my $purchase_time = $t->app->format_iso_datetime($dt);
  my $quantised_day = $t->app->format_iso_datetime($dt->clone->truncate(to => 'day'));
  my $quantised_hour = $t->app->format_iso_datetime($dt->clone->truncate(to => 'hour'));
  create_transaction(10, $purchase_time);
  increment_day(10, $quantised_day);
  increment_hour(10, $quantised_hour);
  if ( $i % 2 == 0 ) {
    create_transaction(20, $purchase_time);
    increment_day(20, $quantised_day);
    increment_hour(20, $quantised_hour);
  }
  if ( $i % 3 == 0 ) {
    create_transaction(30, $purchase_time);
    increment_day(30, $quantised_day);
    increment_hour(30, $quantised_hour);
  }
  if ( $i % 5 == 0 ) {
    create_transaction(50, $purchase_time);
    increment_day(50, $quantised_day);
    increment_hour(50, $quantised_hour);
  }
  if ( $i % 7 == 0 ) {
    create_transaction(70, $purchase_time);
    increment_day(70, $quantised_day);
    increment_hour(70, $quantised_hour);
  }
}

my $expected_days_array = [ map {
  my $data = $expected_days->{$_};
  {
    quantised => $data->{quantised},
    count => $data->{count},
    sum_value => $data->{sum_value},
    sum_distance => $data->{sum_distance},
    average_value => $data->{sum_value} / $data->{count},
    average_distance => $data->{sum_distance} / $data->{count},
  }
} sort keys %$expected_days ];

my $expected_hours_array = [ map {
  my $data = $expected_hours->{$_};
  {
    quantised => $data->{quantised},
    count => $data->{count},
    sum_value => $data->{sum_value},
    sum_distance => $data->{sum_distance},
    average_value => $data->{sum_value} / $data->{count},
    average_distance => $data->{sum_distance} / $data->{count},
  }
} sort keys %$expected_hours ];

is $t->app->schema->resultset('Transaction')->count, 108, 'Transactions created';

#login to admin
$t->post_ok('/admin', form => {
  email => 'admin@example.com',
  password => 'abc123',
})->status_is(302);

$t->get_ok(
    '/admin/reports/transactions',
    { Accept => 'application/json' }
  )
  ->status_is(200)
  ->json_is('/data', $expected_hours_array)->or($framework->dump_error);

$t->get_ok(
    '/admin/reports/transactions',
    { Accept => 'application/json' },
    form => { scale => 'days' }
  )
  ->status_is(200)
  ->json_is('/data', $expected_days_array)->or($framework->dump_error);

done_testing;
