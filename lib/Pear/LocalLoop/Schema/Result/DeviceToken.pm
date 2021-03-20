package Pear::LocalLoop::Schema::Result::DeviceToken;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    qw/
      InflateColumn::DateTime
      TimeStamp
      FilterColumn
      /
);

__PACKAGE__->table("device_tokens");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "user_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "token" => {
        data_type   => "varchar",
        size        => 200,
        is_nullable => 0,
    },
    "register_date" => {
        data_type     => "datetime",
        set_on_create => 1,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "user",
    "Pear::LocalLoop::Schema::Result::User",
    { id            => "user_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->has_many(
    "device_subscriptions",
    "Pear::LocalLoop::Schema::Result::DeviceSubscription",
    { "foreign.device_token_id" => "self.id" },
    { cascade_copy              => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( 'topics' => 'device_subscriptions', 'topic' );

1;
