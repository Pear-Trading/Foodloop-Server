package Pear::LocalLoop::Schema::Result::ImportSet;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    qw/
      InflateColumn::DateTime
      TimeStamp
      /
);

__PACKAGE__->table("import_sets");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "date" => {
        data_type     => "datetime",
        set_on_create => 1,
        is_nullable   => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
    "values",
    "Pear::LocalLoop::Schema::Result::ImportValue",
    { "foreign.set_id" => "self.id" },
    { cascade_copy     => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "lookups",
    "Pear::LocalLoop::Schema::Result::ImportLookup",
    { "foreign.set_id" => "self.id" },
    { cascade_copy     => 0, cascade_delete => 0 },
);

1;
