package Pear::LocalLoop::Schema::Result::Transaction;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/
  InflateColumn::DateTime
  TimeStamp
/);

__PACKAGE__->table("transactions");

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
    data_type => "numeric",
    size => [ 100, 0 ],
    is_nullable => 0,
  },
  "proof_image" => {
    data_type => "text",
    is_nullable => 1,
  },
  "submitted_at" => {
    data_type => "datetime",
    is_nullable => 0,
    set_on_create => 1,
  },
  "purchase_time" => {
    data_type => "datetime",
    timezone => "UTC",
    is_nullable => 0,
    set_on_create => 1,
  },
  "essential" => {
    data_type => "boolean",
    default_value => \"false",
    is_nullable => 0,
  },
  distance => {
    data_type => 'numeric',
    size => [15],
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "buyer",
  "Pear::LocalLoop::Schema::Result::Entity",
  { id => "buyer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "seller",
  "Pear::LocalLoop::Schema::Result::Entity",
  { id => "seller_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->might_have(
  "category",
  "Pear::LocalLoop::Schema::Result::TransactionCategory" => "transaction_id",
);

__PACKAGE__->has_one(
    "meta",
    "Pear::LocalLoop::Schema::Result::TransactionMeta",
    { 'foreign.transaction_id' => 'self.id' },
);

__PACKAGE__->has_many(
    "external_reference",
    "Pear::LocalLoop::Schema::Result::TransactionExternal",
    { 'foreign.transaction_id' => 'self.id' },
);

sub sqlt_deploy_hook {
  my ( $source_instance, $sqlt_table ) = @_;
  my $pending_field = $sqlt_table->get_field('essential');
  if ( $sqlt_table->schema->translator->producer_type =~ /SQLite$/ ) {
    $pending_field->{default_value} = 0;
  } else {
    $pending_field->{default_value} = \"false";
  }
}

1;
