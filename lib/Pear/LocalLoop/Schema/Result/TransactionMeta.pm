package Pear::LocalLoop::Schema::Result::TransactionMeta;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("transactions_meta");

__PACKAGE__->add_columns(
    "id" => {
        data_type => "integer",
        is_auto_increment => 1,
        is_nullable => 0,
    },
    "transaction_id" => {
        data_type => "integer",
        is_foreign_key => 1,
        is_nullable => 0,
    },
    "net_value" => {
        data_type => "numeric",
        size => [ 100, 0 ],
        is_nullable => 0,
    },
    "sales_tax_value" => {
        data_type => "numeric",
        size => [ 100, 0 ],
        is_nullable => 0,
    },
    "gross_value" => {
        data_type => "numeric",
        size => [ 100, 0 ],
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "transaction",
    "Pear::LocalLoop::Schema::Result::Transaction",
    { 'foreign.id' => 'self.transaction_id' },
);

__PACKAGE__->might_have(
    "category",
    "Pear::LocalLoop::Schema::Result::TransactionCategory" => "transaction_id",
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
