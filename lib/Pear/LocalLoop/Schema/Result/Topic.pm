package Pear::LocalLoop::Schema::Result::Topic;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( qw/
  InflateColumn::DateTime
  TimeStamp
  FilterColumn
/);

__PACKAGE__->table("topics");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name" => {
    data_type => "varchar",
    size => 200,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "device_subscriptions",
  "Pear::LocalLoop::Schema::Result::DeviceSubscription",
  { "foreign.topic_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many('device_tokens' => 'device_subscriptions', 'device_token');

1;
