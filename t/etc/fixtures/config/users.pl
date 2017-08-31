#! /usr/bin/env perl

use strict;
use warnings;

use DBIx::Class::Fixtures;
use FindBin qw/ $Bin /;
use lib "$Bin/../../../../lib";
use Pear::LocalLoop::Schema;
use DateTime;

my $fixtures = DBIx::Class::Fixtures->new({
  config_dir => "$Bin",
});

my $schema = Pear::LocalLoop::Schema->connect('dbi:SQLite::memory:');

$schema->deploy;

$schema->resultset('Leaderboard')->populate([
  [ qw/ name type / ],
  [ 'Daily Total', 'daily_total' ],
  [ 'Daily Count', 'daily_count' ],
  [ 'Weekly Total', 'weekly_total' ],
  [ 'Weekly Count', 'weekly_count' ],
  [ 'Monthly Total', 'monthly_total' ],
  [ 'Monthly Count', 'monthly_count' ],
  [ 'All Time Total', 'all_time_total' ],
  [ 'All Time Count', 'all_time_count' ],
]);

my $user1 = {
  customer => {
    full_name    => 'Test User1',
    display_name => 'Test User1',
    postcode     => 'LA1 1AA',
    year_of_birth => 2006,
  },
  email        => 'test1@example.com',
  password     => 'abc123',
};

my $user2 = {
  customer => {
    full_name    => 'Test User2',
    display_name => 'Test User2',
    postcode     => 'LA1 1AA',
    year_of_birth => 2006,
  },
  email        => 'test2@example.com',
  password     => 'abc123',
};

my $user3 = {
  customer => {
    full_name    => 'Test User3',
    display_name => 'Test User3',
    postcode     => 'LA1 1AA',
    year_of_birth => 2006,
  },
  email        => 'test3@example.com',
  password     => 'abc123',
};

my $user4 = {
  customer => {
    full_name    => 'Test User4',
    display_name => 'Test User4',
    postcode     => 'LA1 1AA',
    year_of_birth => 2006,
  },
  email        => 'test4@example.com',
  password     => 'abc123',
};

my $org = {
  organisation => {
    name        => 'Test Org',
    street_name => 'Test Street',
    town        => 'Lancaster',
    postcode    => 'LA1 1AA',
  },
  email       => 'org@example.com',
  password    => 'abc123',
};

$schema->resultset('User')->create( $_ )
  for ( $user1, $user2, $user3, $user4, $org );

my $data_set = 'users';

$fixtures->dump({
  all => 1,
  schema => $schema,
  directory => "$Bin/../data/" . $data_set,
});

