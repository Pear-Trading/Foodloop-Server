use utf8;
package Pear::LocalLoop::Schema::Result::AgeRange;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("age_ranges");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "string",
  { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(["string"]);

__PACKAGE__->has_many(
  "customers",
  "Pear::LocalLoop::Schema::Result::Customer",
  { "foreign.age_range_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
