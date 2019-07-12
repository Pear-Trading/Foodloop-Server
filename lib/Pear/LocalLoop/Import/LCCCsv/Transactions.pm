package Pear::LocalLoop::Import::LCCCsv::Transactions;
use Moo;
use DateTime;
use DateTime::Format::Strptime;

extends qw/Pear::LocalLoop::Import::LCCCsv/;

has '+csv_required_columns' => (
  builder => sub { return [ (
  'transaction_id',
  'supplier_id',
  'net_amount',
  'vat amount',
  'gross_amount',
  )]},
);

sub import_csv {
  my ($self) = @_;

  my $rows = $self->csv_data;
  my $lcc_org = $self->schema->resultset('Organisation')->find({
    name => "Lancashire County Council",
    street_name => "County Hall"
  });
  unless ($lcc_org) {
    Pear::LocalLoop::Error->throw("Cannot find LCC Organisation, please contact an admin");
  }
  foreach my $row ( @{$rows} ) {
    $self->_row_to_result($row, $lcc_org);
  }
}

sub _row_to_result {
  my ( $self, $row, $lcc_org ) = @_;

    my $supplier_id = $row->{supplier_id};

    my $organisation = $self->schema->resultset('Organisation')->find({
      'external_reference.external_id' => $supplier_id
    }, { join => 'external_reference' });

    unless ($organisation) {
      Pear::LocalLoop::Error->throw("Cannot find an organisation with supplier_id $supplier_id");
    }

    my $date_formatter = DateTime::Format::Strptime->new(
      pattern => '%m/%d/%Y',
      time_zone => 'Europe/London'
    );

    my $paid_date = ( $row->{paid_date} ?
      $date_formatter->parse_datetime($row->{paid_date}) :
      $date_formatter->parse_datetime($row->{invoice_date}) );

    my $gross_value = $row->{gross_amount};
    $gross_value =~ s/,//g;
    my $sales_tax_value = $row->{"vat amount"};
    $sales_tax_value =~ s/,//g;
    my $net_value = $row->{net_amount};
    $net_value =~ s/,//g;

    # TODO negative values are sometimes present
    $self->external_result->find_or_create_related('transactions', {
      external_id => $row->{transaction_id},
      transaction => {
        seller => $organisation->entity,
        buyer => $lcc_org->entity,
        purchase_time => $paid_date,
        value => $gross_value * 100000,
        meta => {
          gross_value => $gross_value * 100000,
          sales_tax_value => $sales_tax_value * 100000,
          net_value => $net_value * 100000,
        },
      }
    });
}

1;
