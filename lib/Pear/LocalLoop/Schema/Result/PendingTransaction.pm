package Pear::LocalLoop::Schema::Result::PendingTransaction;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( qw/
  InflateColumn::DateTime
  TimeStamp
/);

__PACKAGE__->table("pending_transactions");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "buyer_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "seller_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "value" => {
    data_type => "decimal",
    size => [ 16, 2 ],
    is_nullable => 0,
  },
  "proof_image" => {
    data_type => "text",
    is_nullable => 0,
  },
  "submitted_at" => {
    data_type => "datetime",
    is_nullable => 0,
    set_on_create => 1,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "buyer",
  "Pear::LocalLoop::Schema::Result::User",
  { id => "buyer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "seller",
  "Pear::LocalLoop::Schema::Result::PendingOrganisation",
  { id => "seller_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
