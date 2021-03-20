package Pear::LocalLoop::Schema::Result::EntityAssociation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("entity_association");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "entity_id" => {
        data_type      => 'integer',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    "lis" => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
    },
    "esta" => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( "entity", "Pear::LocalLoop::Schema::Result::Entity",
    "entity_id", );
