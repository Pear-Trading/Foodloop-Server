package Pear::LocalLoop::Plugin::Minion::Job::csv_transaction_import;
use Mojo::Base 'Pear::LocalLoop::Plugin::Minion::Job';

use Pear::LocalLoop::Import::LCCCsv::Transactions;

sub run {
  my ( $self, $filename ) = @_;

  my $csv_import = Pear::LocalLoop::Import::LCCCsv::Transactions->new(
    csv_file => $filename,
    schema => $self->app->schema
  )->import_csv;
}

1;
