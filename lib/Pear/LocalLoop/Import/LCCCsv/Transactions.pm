package Pear::LocalLoop::Import::LCCCsv::Transactions;
use Moo;
use DateTime;
use DateTime::Format::Strptime;

extends qw/Pear::LocalLoop::Import::LCCCsv/;

has '+csv_required_columns' => (
  builder => sub { return [ qw/
  transaction_id
  supplier_id
  net_amount
  gross_amount
  / ]},
);

sub import_csv {
  my ($self) = @_;

  my $rows = $self->csv_data;
  my $lcc_org = $self->schema->resultset('Organisation')->find( name => "Lancashire County Council" );
  foreach my $row ( @{$rows} ) {
    $self->_row_to_result($row, $lcc_org);
  }
  return 1;
}

sub _row_to_result {
  my ( $self, $row, $lcc_org ) = @_;

    Dwarn $row;

    my $organisation = $self->schema->resultset('Organisation')->find( external_id => $row->{supplier_id} );

    my $date_formatter = DateTime::Format::Strptime->new(
      pattern => '%Y/%m/%d'
    );

    my $paid_date = ( $row->{paid_date} ? $date_formatter->parse_datetime($row->{paid_date}) : DateTime->today );

    $self->external_result->find_or_create_related('transactions', {
      transaction_id => $row->{transaction_id},
      transaction => {
        seller => $organisation->entity->id,
        buyer => $lcc_org,
        purchase_time => $paid_date,
        value => $row->{net_amount},
        meta => {
          transaction_id => $row->{transaction_id},
          gross_value => $row->{gross_amount},
          sales_tax_value => $row->{"vat amount"},
          net_value => $row->{net_amount},
        },
      }
    });
}

1;
