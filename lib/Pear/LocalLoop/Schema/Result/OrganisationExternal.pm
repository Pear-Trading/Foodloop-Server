package Pear::LocalLoop::Schema::Result::OrganisationExternal;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("organisations_external");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "org_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "external_reference_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "external_id" => {
        data_type   => "varchar",
        size        => 255,
        is_nullable => 0,
    }
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( [qw/external_reference_id external_id/] );

__PACKAGE__->belongs_to(
    "organisation",
    "Pear::LocalLoop::Schema::Result::Organisation",
    { 'foreign.id' => 'self.org_id' },
);

__PACKAGE__->belongs_to(
    "external_reference",
    "Pear::LocalLoop::Schema::Result::ExternalReference",
    { 'foreign.id' => 'self.external_reference_id' },
);

1;
