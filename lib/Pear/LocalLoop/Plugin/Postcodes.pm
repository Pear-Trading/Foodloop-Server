package Pear::LocalLoop::Plugin::Postcodes;
use Mojo::Base 'Mojolicious::Plugin';

use Geo::UK::Postcode::Regex;
use GIS::Distance;

sub register {
    my ( $plugin, $app, $conf ) = @_;

    $app->helper(
        get_location_from_postcode => sub {
            my ( $c, $postcode, $usertype ) = @_;
            my $postcode_obj = Geo::UK::Postcode::Regex->parse($postcode);

            my $location;

            unless ( defined $postcode_obj
                && $postcode_obj->{non_geographical} )
            {
                my $pc_result = $c->schema->resultset('GbPostcode')->find(
                    {
                        incode  => $postcode_obj->{incode},
                        outcode => $postcode_obj->{outcode},
                    }
                );
                if ( defined $pc_result ) {

                    # Force truncation here as SQLite is stupid
                    $location = {
                        latitude => (
                            $usertype eq 'customer'
                            ? int( $pc_result->latitude * 100 ) / 100
                            : $pc_result->latitude
                        ),
                        longitude => (
                            $usertype eq 'customer'
                            ? int( $pc_result->longitude * 100 ) / 100
                            : $pc_result->longitude
                        ),
                    };
                }
            }
            return $location;
        }
    );

    $app->helper(
        get_distance_from_coords => sub {
            my ( $c, $buyer, $seller ) = @_;

            my $gis = GIS::Distance->new();

            my $buyer_lat   = $buyer->latitude;
            my $buyer_long  = $buyer->longitude;
            my $seller_lat  = $seller->latitude;
            my $seller_long = $seller->longitude;

            if (   $buyer_lat
                && $buyer_long
                && $seller_lat
                && $seller_long )
            {
                return int(
                    $gis->distance(
                        $buyer_lat,
                        $buyer_long => $seller_lat,
                        $seller_long
                    )->meters
                );
            }
            return;
        }
    );

    return 1;
}

1;
