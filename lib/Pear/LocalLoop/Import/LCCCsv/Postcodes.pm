package Pear::LocalLoop::Import::LCCCsv::Postcodes;
use Moo;

use Geo::UK::Postcode::Regex;

extends qw/Pear::LocalLoop::Import::LCCCsv/;

has '+csv_required_columns' => (
    builder => sub {
        return [
            qw/
              postcode
              ward
              /
        ];
    },
);

sub import_csv {
    my ($self) = @_;

    $self->check_headers;

    while ( my $row = $self->get_csv_line ) {
        $self->_row_to_result($row);
    }
    
    return 1;
}

sub _row_to_result {
    my ( $self, $row ) = @_;

    my $postcode_obj = Geo::UK::Postcode::Regex->parse( $row->{postcode} );

    my $ward = $self->schema->resultset('GbWard')
      ->find_or_create( ward => $row->{ward} );

    my $postcode_r = $self->schema->resultset('GbPostcode')->find(
        {
            outcode => $postcode_obj->{outcode},
            incode  => $postcode_obj->{incode},
        }
    );

    return unless $postcode_r;
    return if $postcode_r->ward;

    $postcode_r->update( { ward_id => $ward->id } );
    
    return 1;
}

1;
