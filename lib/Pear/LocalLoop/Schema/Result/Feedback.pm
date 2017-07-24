package Pear::LocalLoop::Schema::Result::Feedback;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("feedback");

__PACKAGE__->load_components(qw/
  InflateColumn::DateTime
  TimeStamp
/);

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id" => {
    data_type => "integer",
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "submitted_at" => {
    data_type => "datetime",
    is_nullable => 0,
    set_on_create => 1,
  },
  "feedbacktext" => {
    data_type => "text",
    is_nullable => 0,
  },
  "app_name" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "package_name" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "version_code" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "version_number" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

_PACKAGE__->belongs_to(
  "user",
  "Pear::LocalLoop::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
