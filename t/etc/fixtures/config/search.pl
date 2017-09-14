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

$fixtures->populate({
  directory => "$Bin/../data/users",
  no_deploy => 1,
  schema => $schema,
});

my @orgs = (
  {
    organisation => {
      name        => 'Avanti Bar & Restaurant',
      street_name => '57 Main St',
      town        => 'Kirkby Lonsdale',
      postcode    => 'LA6 2AH',
      sector      => 'I',
    },
    type => "organisation",
  },
  {
    organisation => {
      name        => 'Full House Noodle Bar',
      street_name => '21 Common Garden St',
      town        => 'Lancaster',
      postcode    => 'LA1 1XD',
      sector      => 'I',
    },
    type => "organisation",
  },
  {
    organisation => {
      name        => 'The Quay\'s Fishbar',
      street_name => '1 Adcliffe Rd',
      town        => 'Lancaster',
      postcode    => 'LA1 1SS',
      sector      => 'I',
    },
    type => "organisation",
  },
  {
    organisation => {
      name        => 'Dan\'s Fishop',
      street_name => '56 North Rd',
      town        => 'Lancaster',
      postcode    => 'LA1 1LT',
      sector      => 'I',
    },
    type => "organisation",
  },
  {
    organisation => {
      name        => 'Hodgeson\'s Chippy',
      street_name => '96 Prospect St',
      town        => 'Lancaster',
      postcode    => 'LA1 3BH',
      sector      => 'I',
    },
    type => "organisation",
  },
);

$schema->resultset('Entity')->create( $_ ) for @orgs;

my $data_set = 'search';

$fixtures->dump({
  all => 1,
  schema => $schema,
  directory => "$Bin/../data/" . $data_set,
});

