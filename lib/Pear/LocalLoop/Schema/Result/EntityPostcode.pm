package Pear::LocalLoop::Schema::Result::EntityPostcode;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('entities_postcodes');

__PACKAGE__->add_columns(
    outcode => {
        data_type   => 'char',
        size        => 4,
        is_nullable => 0,
    },
    incode => {
        data_type   => 'char',
        size        => 3,
        is_nullable => 0,
    },
    entity_id => {
        data_type      => 'integer',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
);

__PACKAGE__->set_primary_key(qw/ outcode incode entity_id /);

__PACKAGE__->belongs_to( "entity", "Pear::LocalLoop::Schema::Result::Entity",
    "entity_id", );

__PACKAGE__->belongs_to(
    "gb_postcode",
    "Pear::LocalLoop::Schema::Result::GbPostcode",
    {
        "foreign.outcode" => "self.outcode",
        "foreign.incode"  => "self.incode",
    },
);
1;
