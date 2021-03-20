package Pear::LocalLoop::Schema::Result::LeaderboardValue;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("leaderboard_values");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "entity_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "set_id" => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "position" => {
        data_type   => "integer",
        is_nullable => 0,
    },
    "value" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "trend" => {
        data_type     => "integer",
        default_value => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( [qw/ entity_id set_id /] );

__PACKAGE__->belongs_to(
    "set",
    "Pear::LocalLoop::Schema::Result::LeaderboardSet",
    { "foreign.id" => "self.set_id" },
    {
        is_deferrable => 0,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

__PACKAGE__->belongs_to(
    "entity",
    "Pear::LocalLoop::Schema::Result::Entity",
    { "foreign.id" => "self.entity_id" },
    {
        is_deferrable => 0,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

1;
