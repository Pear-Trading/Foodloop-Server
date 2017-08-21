#! /usr/bin/env perl

use strict;
use warnings;

use 5.020;

use DBIx::Class::Fixtures;
use FindBin qw/ $Bin /;
use lib "$Bin/../../../../lib";
use Pear::LocalLoop::Schema;
use DateTime;
use Devel::Dwarn;

my $fixtures = DBIx::Class::Fixtures->new({
  config_dir => "$Bin",
});

my $schema = Pear::LocalLoop::Schema->connect('dbi:SQLite::memory:');

$schema->deploy;

$fixtures->populate({
  directory => "$Bin/../data/transactions",
  no_deploy => 1,
  schema => $schema,
});

my $trans_rs = $schema->resultset('Transaction')->search( undef, { order_by => { '-asc' => 'purchase_time' } } );

my $first = $trans_rs->first->purchase_time;

# Start with the first monday after this transaction
my $beginning_of_week = $first->clone->truncate( to => 'week' );

# Start with the first month after this transaction
my $beginning_of_month = $first->clone->truncate( to => 'month' );

say "First Entry";
say $first->iso8601;
say "First Week";
say $beginning_of_week->iso8601;
say "First Month";
say $beginning_of_month->iso8601;

$trans_rs = $schema->resultset('Transaction')->search( undef, { order_by => { '-desc' => 'purchase_time' } } );

my $last = $trans_rs->first->purchase_time->subtract( days => 1 );

my $end_week = $last->clone->truncate( to => 'week' )->subtract( weeks => 1 );

my $end_month = $last->clone->truncate( to => 'month' );

say "Last Entry";
say $last->iso8601;
say "Last Week";
say $end_week->iso8601;
say "Last Month";
say $end_month->iso8601;

say "Calculating Daily Leaderboards from " . $first->iso8601 . " to " . $last->iso8601;

my $leaderboard_rs = $schema->resultset('Leaderboard');
my $daily_date = $first->clone;

while ( $daily_date <= $last ) {
  say "Creating Daily Total for " . $daily_date->iso8601;
  $leaderboard_rs->create_new( 'daily_total', $daily_date );
  say "Creating Daily Count for " . $daily_date->iso8601;
  $leaderboard_rs->create_new( 'daily_count', $daily_date );
  $daily_date->add( days => 1 );
}

say "Created " . $leaderboard_rs->find({ type => 'daily_total' })->sets->count . " Daily Total boards";
say "Created " . $leaderboard_rs->find({ type => 'daily_count' })->sets->count . " Daily Count boards";

my $weekly_date = $beginning_of_week->clone;

while ( $weekly_date <= $end_week ) {
  say "Creating Weekly Total for " . $weekly_date->iso8601;
  $leaderboard_rs->create_new( 'weekly_total', $weekly_date );
  say "Creating Weekly Count for " . $weekly_date->iso8601;
  $leaderboard_rs->create_new( 'weekly_count', $weekly_date );
  $weekly_date->add( weeks => 1 );
}

say "Created " . $leaderboard_rs->find({ type => 'weekly_total' })->sets->count . " Weekly Total boards";
say "Created " . $leaderboard_rs->find({ type => 'weekly_count' })->sets->count . " Weekly Count boards";

my $monthly_date = $beginning_of_month->clone;

while ( $monthly_date <= $end_month ) {
  say "Creating Monthly Total for " . $monthly_date->iso8601;
  $leaderboard_rs->create_new( 'monthly_total', $monthly_date );
  say "Creating Monthly Count for " . $monthly_date->iso8601;
  $leaderboard_rs->create_new( 'monthly_count', $monthly_date );
  $monthly_date->add( months => 1 );
}

say "Created " . $leaderboard_rs->find({ type => 'monthly_total' })->sets->count . " Monthly Total boards";
say "Created " . $leaderboard_rs->find({ type => 'monthly_count' })->sets->count . " Monthly Count boards";

my $data_set = 'leaderboards';

$fixtures->dump({
  all => 1,
  schema => $schema,
  directory => "$Bin/../data/" . $data_set,
});
