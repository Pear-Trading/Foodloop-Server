package Pear::LocalLoop::Schema::Result::OrganisationType;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("organisation_types");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "key" => {
        data_type   => "varchar",
        size        => 255,
        is_nullable => 0,
    },
    "name" => {
        data_type   => "varchar",
        size        => 255,
        is_nullable => 0,
    }
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( [qw/key/] );

__PACKAGE__->has_many(
    "organisations",
    "Pear::LocalLoop::Schema::Result::Organisation",
    { 'foreign.type_id' => 'self.id' },
);

1;
