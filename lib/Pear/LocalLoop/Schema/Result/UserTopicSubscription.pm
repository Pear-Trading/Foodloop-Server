package Pear::LocalLoop::Schema::Result::UserTopicSubscription;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("user_topic_subscriptions");

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
    "topic_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "user",
    "Pear::LocalLoop::Schema::Result::User",
    "user_id",
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
    "topic",
    "Pear::LocalLoop::Schema::Result::Topic",
    "topic_id",
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
