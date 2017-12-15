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

my $entity1 = {
  customer => {
    full_name    => 'Test User1',
    display_name => 'Test User1',
    postcode     => 'LA1 1AA',
    year_of_birth => 2006,
  },
  user => {
    email    => 'test1@example.com',
    password => 'abc123',
  },
  type => "customer",
};

my $entity2 = {
  customer => {
    full_name     => 'Test User2',
    display_name  => 'Test User2',
    postcode      => 'LA1 1AA',
    year_of_birth => 2006,
  },
  user => {
    email    => 'test2@example.com',
    password => 'abc123',
  },
  type => "customer",
};

my $entity3 = {
  customer => {
    full_name     => 'Test User3',
    display_name  => 'Test User3',
    postcode      => 'LA1 1AA',
    year_of_birth => 2006,
  },
  user => {
    email    => 'test3@example.com',
    password => 'abc123',
  },
  type => "customer",
};

my $entity4 = {
  customer => {
    full_name     => 'Test User4',
    display_name  => 'Test User4',
    postcode      => 'LA1 1AA',
    year_of_birth => 2006,
  },
  user => {
    email    => 'test4@example.com',
    password => 'abc123',
  },
  type => "customer",
};

my $entity5 = {
  organisation => {
    name        => 'Test Org',
    street_name => 'Test Street',
    town        => 'Lancaster',
    postcode    => 'LA1 1AA',
    sector      => 'A',
  },
  user => {
    email    => 'org@example.com',
    password => 'abc123',
  },
  type => "organisation",
};

my $entity6 = {
  customer => {
    full_name     => 'Test Admin',
    display_name  => 'Test Admin',
    postcode      => 'LA1 1AA',
    year_of_birth => 2006,
  },
  user => {
    email    => 'admin@example.com',
    password => 'abc123',
    is_admin => \"1",
  },
  type => "customer",
};

$schema->resultset('Entity')->create( $_ )
  for ( $entity1, $entity2, $entity3, $entity4, $entity5, $entity6 );

my $data_set = 'users';

$fixtures->dump({
  all => 1,
  schema => $schema,
  directory => "$Bin/../data/" . $data_set,
});
