package Pear::LocalLoop::Schema::Result::ExternalReference;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("external_references");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "name" => {
        data_type   => "varchar",
        size        => 255,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->has_many(
    'transactions',
    "Pear::LocalLoop::Schema::Result::TransactionExternal",
    { 'foreign.external_reference_id' => 'self.id' },
);

__PACKAGE__->has_many(
    'organisations',
    "Pear::LocalLoop::Schema::Result::OrganisationExternal",
    { 'foreign.external_reference_id' => 'self.id' },
);

1;
