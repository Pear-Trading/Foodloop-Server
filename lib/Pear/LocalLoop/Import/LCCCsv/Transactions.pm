package Pear::LocalLoop::Import::LCCCsv::Transactions;
use Moo;
use DateTime;
use DateTime::Format::Strptime;

use Geo::UK::Postcode::Regex;

extends qw/Pear::LocalLoop::Import::LCCCsv/;

has target_entity_id => (
    is       => 'ro',
    required => 1,
);

has target_entity => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        my $entity =
          $self->schema->resultset('Entity')->find( $self->target_entity_id );
        Pear::LocalLoop::Error->throw(
            "Cannot find LCC Entity, did you pass the right id?")
          unless $entity;
        return $entity;
    },
);

has '+csv_required_columns' => (
    builder => sub {
        return [
            (
                'transaction_id', 'supplier_id',
                'net_amount',     'vat amount',
                'gross_amount',
            )
        ];
    },
);

sub import_csv {
    my ($self) = @_;

    $self->check_headers;
    my $lcc_org = $self->target_entity;

    while ( my $row = $self->get_csv_line ) {
        $self->_row_to_result( $row, $lcc_org );
    }
    
    return 1;
}

sub _row_to_result {
    my ( $self, $row, $lcc_org ) = @_;

    my $supplier_id = $row->{supplier_id};

    my $organisation = $self->schema->resultset('Organisation')->find(
        {
            'external_reference.external_id' => $supplier_id
        },
        { join => 'external_reference' }
    );

    unless ($organisation) {

# Pear::LocalLoop::Error->throw("Cannot find an organisation with supplier_id $supplier_id");

        return unless $row->{'Company Name (WHO)'};

        my $town = $row->{post_town};

        unless ($town) {
            my $postcode_obj =
              Geo::UK::Postcode::Regex->parse( $row->{post_code} );
            $town = Geo::UK::Postcode::Regex->outcode_to_posttowns(
                $postcode_obj->{outcode} );
            $town = $town->[0];
        }

        return
          if $self->external_result->organisations->find(
            { external_id => $row->{supplier_id} } );

        $organisation = $self->schema->resultset('Entity')->create(
            {
                type         => 'organisation',
                organisation => {
                    name               => $row->{'Company Name (WHO)'},
                    street_name        => $row->{"address line 1"},
                    town               => $town,
                    postcode           => $row->{post_code},
                    country            => $row->{country_code},
                    external_reference => [
                        {
                            external_reference => $self->external_result,
                            external_id        => $row->{supplier_id},
                        }
                    ],
                }
            }
        );
    }

    my $date_formatter = DateTime::Format::Strptime->new(
        pattern   => '%m/%d/%Y',
        time_zone => 'Europe/London'
    );

    my $paid_date = (
          $row->{paid_date}
        ? $date_formatter->parse_datetime( $row->{paid_date} )
        : $date_formatter->parse_datetime( $row->{invoice_date} )
    );

    my $gross_value = $row->{gross_amount};
    $gross_value =~ s/,//g;
    my $sales_tax_value = $row->{"vat amount"};
    $sales_tax_value =~ s/,//g;
    my $net_value = $row->{net_amount};
    $net_value =~ s/,//g;

    # TODO negative values are sometimes present
    my $external_transaction = $self->external_result->update_or_create_related(
        'transactions',
        {    # This is a TransactionExternal result
            external_id => $row->{transaction_id},
        }
    );

    my $transaction_result = $external_transaction->update_or_create_related(
        'transaction',
        {
            seller        => $organisation->entity,
            buyer         => $lcc_org,
            purchase_time => $paid_date,
            value         => $gross_value * 100000,
        }
    );

    my $meta_result = $transaction_result->update_or_create_related(
        'meta',
        {
            gross_value     => $gross_value * 100000,
            sales_tax_value => $sales_tax_value * 100000,
            net_value       => $net_value * 100000,
            (
                $row->{"local service"}
                ? ( local_service => $row->{"local service"} )
                : ()
            ),
            (
                $row->{"regional service"}
                ? ( regional_service => $row->{"regional service"} )
                : ()
            ),
            (
                $row->{"national service"}
                ? ( national_service => $row->{"national service"} )
                : ()
            ),
            (
                $row->{"private household rebate"}
                ? ( private_household_rebate =>
                      $row->{"private household rebate"} )
                : ()
            ),
            (
                $row->{"business tax and rebate"}
                ? ( business_tax_and_rebate =>
                      $row->{"business tax and rebate"} )
                : ()
            ),
            (
                $row->{"stat loc gov"}
                ? ( stat_loc_gov => $row->{"stat loc gov"} )
                : ()
            ),
            (
                $row->{"central loc gov"}
                ? ( central_loc_gov => $row->{"central loc gov"} )
                : ()
            ),
        }
    );
    
    return 1;
}

1;
