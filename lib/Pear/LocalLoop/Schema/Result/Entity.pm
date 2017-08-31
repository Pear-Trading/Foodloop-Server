package Pear::LocalLoop::Schema::Result::Entity;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("entities");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "type" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->might_have(
  "customer",
  "Pear::LocalLoop::Schema::Result::Customer" => "entity_id",
);

__PACKAGE__->might_have(
  "organisation",
  "Pear::LocalLoop::Schema::Result::Organisation" => "entity_id",
);

__PACKAGE__->might_have(
  "user",
  "Pear::LocalLoop::Schema::Result::User" => "entity_id",
);

__PACKAGE__->has_many(
  "purchases",
  "Pear::LocalLoop::Schema::Result::Transaction",
  { "foreign.buyer_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "sales",
  "Pear::LocalLoop::Schema::Result::Transaction",
  { "foreign.seller_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
