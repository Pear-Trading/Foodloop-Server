package Pear::LocalLoop::Import::LCCCsv::Suppliers;
use Moo;

extends qw/Pear::LocalLoop::Import::LCCCsv/;

has '+csv_required_columns' => (
  builder => sub { return [ qw/
  supplier_id
  name
  / ]},
);

sub import_csv {
  my ($self) = @_;

  $self->check_headers;

  while ( my $row = $self->get_csv_line ) {
    $self->_row_to_result($row);
  }
}

sub _row_to_result {
  my ( $self, $row ) = @_;

  my $addr2 = $row->{post_town};

  my $address = ( defined $addr2 ? ( $row->{"address line 2"} . ' ' . $addr2) : $row->{"address line 2"} );

  return if $self->external_result->organisations->find({external_id => $row->{supplier_id}});

  $self->schema->resultset('Entity')->create({
    type => 'organisation',
    organisation => {
      name => $row->{name},
      street_name => $row->{"address line 1"},
      town => $address,
      postcode => $row->{post_code},
      country => $row->{country_code},
      external_reference => [ {
        external_reference => $self->external_result,
        external_id => $row->{supplier_id},
      } ],
    }
  });
}

1;
