package Pear::LocalLoop::Plugin::Minion::Job::csv_postcode_import;
use Mojo::Base 'Pear::LocalLoop::Plugin::Minion::Job';

use Pear::LocalLoop::Import::LCCCsv::Postcodes;

sub run {
    my ( $self, $filename ) = @_;

    my $csv_import = Pear::LocalLoop::Import::LCCCsv::Postcodes->new(
        csv_file => $filename,
        schema   => $self->app->schema
    )->import_csv;

    return 1;
}

1;
