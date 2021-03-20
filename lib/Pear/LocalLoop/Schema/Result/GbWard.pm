package Pear::LocalLoop::Schema::Result::GbWard;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('gb_wards');

__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    ward => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key(qw/ id /);

__PACKAGE__->has_many(
    "postcodes",
    "Pear::LocalLoop::Schema::Result::GbPostcode",
    { "foreign.ward_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;
