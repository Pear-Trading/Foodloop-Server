package Pear::LocalLoop::Schema::Result::GbPostcode;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('gb_postcodes');

__PACKAGE__->add_columns(
  outcode => {
    data_type => 'char',
    size => 4,
    is_nullable => 0,
  },
  incode => {
    data_type => 'char',
    size => 3,
    is_nullable => 0,
    default_value => '',
  },
  latitude => {
    data_type => 'decimal',
    size => [7,5],
    is_nullable => 1,
    default_value => undef,
  },
  longitude => {
    data_type => 'decimal',
    size => [7,5],
    is_nullable => 1,
    default_value => undef,
  },
  ward_id => {
    data_type => 'integer',
    is_nullable => 1,
    default_value => undef,
  },
);

__PACKAGE__->set_primary_key(qw/ outcode incode /);

__PACKAGE__->belongs_to(
  "ward",
  "Pear::LocalLoop::Schema::Result::GbWard",
  "ward_id",
);

1;
