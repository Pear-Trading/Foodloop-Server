package Pear::LocalLoop::Schema::Result::TransactionRecurring;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    qw/
      InflateColumn::DateTime
      TimeStamp
      /
);

__PACKAGE__->table("transaction_recurring");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "buyer_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "seller_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "value" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "start_time" => {
        data_type   => "datetime",
        timezone    => "UTC",
        is_nullable => 0,
    },
    "last_updated" => {
        data_type                 => "datetime",
        timezone                  => "UTC",
        is_nullable               => 1,
        datetime_undef_if_invalid => 1,
    },
    "essential" => {
        data_type     => "boolean",
        default_value => \"false",
        is_nullable   => 0,
    },
    "distance" => {
        data_type   => 'numeric',
        size        => [15],
        is_nullable => 1,
    },
    "category_id" => {
        data_type      => "integer",
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    "recurring_period" => {
        data_type   => "varchar",
        size        => 255,
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "buyer",
    "Pear::LocalLoop::Schema::Result::Entity",
    { id            => "buyer_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
    "seller",
    "Pear::LocalLoop::Schema::Result::Entity",
    { id            => "seller_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
    "category", "Pear::LocalLoop::Schema::Result::Category",
    "category_id", { cascade_delete => 0 },
);

1;
