package Pear::LocalLoop::Schema::Result::LeaderboardSet;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( qw/
  InflateColumn::DateTime
/);

__PACKAGE__->table("leaderboard_sets");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "leaderboard_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "date" => {
    data_type => "datetime",
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "leaderboard",
  "Pear::LocalLoop::Schema::Result::Leaderboard",
  { "foreign.id" => "self.leaderboard_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "values",
  "Pear::LocalLoop::Schema::Result::LeaderboardValue",
  { "foreign.set_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
