package Pear::LocalLoop::Schema::Result::Organisation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "FilterColumn");

__PACKAGE__->table("organisations");

__PACKAGE__->add_columns(
  id => {
    data_type => 'integer',
    is_auto_increment => 1,
    is_nullable => 0,
  },
  entity_id => {
    data_type => 'integer',
    is_nullable => 0,
    is_foreign_key => 1,
  },
  name => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 0,
  },
  street_name => {
    data_type => 'text',
    is_nullable => 1,
  },
  town => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 0,
  },
  postcode => {
    data_type => 'varchar',
    size => 16,
    is_nullable => 1,
  },
  country => {
    data_type => 'varchar',
    size => 255,
    is_nullable => 1,
  },
  sector => {
    data_type => 'varchar',
    size => 1,
    is_nullable => 1,
  },
  pending => {
    data_type => 'boolean',
    default => \"false",
    is_nullable => 0,
  },
  submitted_by_id => {
    data_type => 'integer',
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  "entity",
  "Pear::LocalLoop::Schema::Result::Entity",
  "entity_id",
);

__PACKAGE__->filter_column( pending => {
  filter_to_storage => 'to_bool',
});

# Only works when calling ->deploy, but atleast helps for tests
sub sqlt_deploy_hook {
  my ( $source_instance, $sqlt_table ) = @_;
  my $pending_field = $sqlt_table->get_field('pending');
  if ( $sqlt_table->schema->translator->producer_type =~ /SQLite$/ ) {
    $pending_field->{default_value} = 0;
  } else {
    $pending_field->{default_value} = \"false";
  }
}

sub to_bool {
  my ( $self, $val ) = @_;
  my $driver_name = $self->result_source->schema->storage->dbh->{Driver}->{Name};
  if ( $driver_name eq 'SQLite' ) {
    return $val ? 1 : 0;
  } else {
    return $val ? 'true' : 'false';
  }
}

1;
