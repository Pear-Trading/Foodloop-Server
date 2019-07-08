package Pear::LocalLoop::Plugin::Minion::Job::csv_supplier_import;
use Mojo::Base 'Pear::LocalLoop::Plugin::Minion::Job';
use Devel::Dwarn;

sub run {
  my ( $self, $rows ) = @_;

  foreach my $row ( @{$rows} ) {
    $self->_row_to_result($row);
  }
}

sub _row_to_result {
  my ( $self, $row ) = @_;
  # Dwarn $row->{supplier_id};
  my $addr2 = $row->{post_town};

  my $address = ( defined $addr2 ? ( $row->{"address line 2"} . ' ' . $addr2) : $row->{"address line 2"} );

  $self->external_result->find_or_create_related('organisations', {
    external_id => $row->{supplier_id},
    organisation => {
      name => $row->{name},
      street_name => $row->{"address line 1"},
      town => $address,
      postcode => $row->{post_code},
      country => $row->{country_code},
      entity => { type => 'organisation' },
    }
  });
  $self->app->log->debug('Imported the CSV fully!');
}

1;
