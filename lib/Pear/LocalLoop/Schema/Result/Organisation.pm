package Pear::LocalLoop::Schema::Result::Organisation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "FilterColumn" );

__PACKAGE__->table("organisations");

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    entity_id => {
        data_type      => 'integer',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    name => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    street_name => {
        data_type   => 'text',
        is_nullable => 1,
    },
    town => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
    },
    postcode => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 1,
    },
    country => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
    },

# Stores codes based on https://www.ons.gov.uk/methodology/classificationsandstandards/ukstandardindustrialclassificationofeconomicactivities/uksic2007
    sector => {
        data_type   => 'varchar',
        size        => 1,
        is_nullable => 1,
    },
    pending => {
        data_type     => 'boolean',
        default_value => \"false",
        is_nullable   => 0,
    },
    is_local => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
    },
    is_fair => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
    },
    submitted_by_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    latitude => {
        data_type     => 'decimal',
        size          => [ 8, 5 ],
        is_nullable   => 1,
        default_value => undef,
    },
    longitude => {
        data_type     => 'decimal',
        size          => [ 8, 5 ],
        is_nullable   => 1,
        default_value => undef,
    },
    type_id => {
        data_type      => 'integer',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    social_type_id => {
        data_type      => 'integer',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    is_anchor => {
        data_type     => 'boolean',
        is_nullable   => 0,
        default_value => \'FALSE',
    }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( "entity", "Pear::LocalLoop::Schema::Result::Entity",
    "entity_id", );

__PACKAGE__->belongs_to( "organisation_type",
    "Pear::LocalLoop::Schema::Result::OrganisationType", "type_id", );

__PACKAGE__->belongs_to( "social_type",
    "Pear::LocalLoop::Schema::Result::OrganisationSocialType",
    "social_type_id", );

__PACKAGE__->has_many(
    "external_reference",
    "Pear::LocalLoop::Schema::Result::OrganisationExternal",
    { 'foreign.org_id' => 'self.id' },
);

__PACKAGE__->has_many(
    "payroll",
    "Pear::LocalLoop::Schema::Result::OrganisationPayroll",
    { "foreign.org_id" => "self.id" },
    { cascade_copy     => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "topics",
    "Pear::LocalLoop::Schema::Result::Topic",
    { "foreign.organisation_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->filter_column(
    pending => {
        filter_to_storage => 'to_bool',
    },
    is_local => {
        filter_to_storage => 'to_bool',
    },
    is_anchor => {
        filter_to_storage => 'to_bool',
    }
);

# Only works when calling ->deploy, but atleast helps for tests
sub sqlt_deploy_hook {
    my ( $source_instance, $sqlt_table ) = @_;
    my $pending_field = $sqlt_table->get_field('pending');
    if ( $sqlt_table->schema->translator->producer_type =~ /SQLite$/ ) {
        $pending_field->{default_value} = 0;
    }
    else {
        $pending_field->{default_value} = \"false";
    }

    return 1;
}

sub to_bool {
    my ( $self, $val ) = @_;
    return if !defined $val;
    my $driver_name =
      $self->result_source->schema->storage->dbh->{Driver}->{Name};
    if ( $driver_name eq 'SQLite' ) {
        return $val ? 1 : 0;
    }
    else {
        return $val ? 'true' : 'false';
    }
}

sub user {
    my $self = shift;

    return $self->entity->user;
}

1;
