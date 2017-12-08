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
    latitude     => 54.04,
    longitude    => -2.80,
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
    postcode      => 'LA1 1AB',
    year_of_birth => 2006,
    latitude     => 54.04,
    longitude    => -2.80,
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
    postcode      => 'LA1 1AD',
    year_of_birth => 2006,
    latitude     => 54.05,
    longitude    => -2.80,
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
    postcode      => 'LA1 1AE',
    year_of_birth => 2006,
    latitude     => 54.04,
    longitude    => -2.80,
  },
  user => {
    email    => 'test4@example.com',
    password => 'abc123',
  },
  type => "customer",
};

my $org1 = {
  organisation => {
    name        => 'Test Org',
    street_name => 'Test Street',
    town        => 'Lancaster',
    postcode    => 'LA1 1AF',
    latitude    => 54.04725,
    longitude   => -2.79611,
  },
  user => {
    email    => 'org1@example.com',
    password => 'abc123',
  },
  type => "organisation",
};

my $org2 = {
  organisation => {
    name        => 'Test Org 2',
    street_name => 'Test Street',
    town        => 'Lancaster',
    postcode    => 'LA1 1AG',
    latitude    => 54.04679,
    longitude   => -2.7963,
  },
  user => {
    email    => 'org2@example.com',
    password => 'abc123',
  },
  associations => {
    lis => 1,
    esta => 1,
  },
  type => "organisation",
};

my $admin = {
  customer => {
    full_name     => 'Test Admin',
    display_name  => 'Test Admin',
    postcode      => 'LA1 1AH',
    year_of_birth => 2006,
    latitude     => 54.05,
    longitude    => -2.80,
  },
  user => {
    email    => 'admin@example.com',
    password => 'abc123',
    is_admin => \"1",
  },
  type => "customer",
};

$schema->resultset('Entity')->create( $_ )
  for (
    $entity1,
    $entity2,
    $entity3,
    $entity4,
    $org1,
    $org2,
    $admin,
);

use Geo::UK::Postcode::CodePointOpen;

my $output_dir = 'etc/code-point-open/codepo_gb';
my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => $output_dir );

my $iter = $cpo->read_iterator(
  outcodes => ['LA1'],
  include_lat_long => 1,
  split_postcode => 1,
);

my $pc_rs = $schema->resultset('GbPostcode');

my $i = 1;
while ( my $pc = $iter->() ) {
  $pc_rs->find_or_create(
    {
      outcode   => $pc->{Outcode},
      incode    => $pc->{Incode},
      latitude  => $pc->{Latitude},
      longitude => $pc->{Longitude},
    },
    { key => 'primary' },
  );
  last if $i++ > 10
}

$iter = $cpo->read_iterator(
  outcodes => ['LA2'],
  include_lat_long => 1,
  split_postcode => 1,
);

$i = 1;
while ( my $pc = $iter->() ) {
  $pc_rs->find_or_create(
    {
      outcode   => $pc->{Outcode},
      incode    => $pc->{Incode},
      latitude  => $pc->{Latitude},
      longitude => $pc->{Longitude},
    },
    { key => 'primary' },
  );
  last if $i++ > 10
}

my $data_set = 'full';

$fixtures->dump({
  all => 1,
  schema => $schema,
  directory => "$Bin/../data/" . $data_set,
});
