package Pear::LocalLoop::Schema::Result::AccountToken;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("account_tokens");

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "text", is_nullable => 0 },
    "used",
    { data_type => "integer", default_value => 0, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( ["name"] );

1;
