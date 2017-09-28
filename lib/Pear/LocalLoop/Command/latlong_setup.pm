package Pear::LocalLoop::Command::latlong_setup;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

use Geo::UK::Postcode::Regex;
use GIS::Distance;

has description => 'Set lat/long data on customers and orgs';

has usage => sub { shift->extract_usage };

sub run {
  my ( $self, @args ) = @_;

  my $customer_rs = $self->app->schema->resultset('Customer');
  my $org_rs = $self->app->schema->resultset('Organisation');

  for my $result ( $customer_rs->all, $org_rs->all ) {
    $self->_set_lat_long_for_result( $result );
  }

  my $transaction_rs = $self->app->schema->resultset('Transaction');

  for my $result ( $transaction_rs->all ) {
    my $distance = $self->_calculate_distance(
      $result->buyer->${\$result->buyer->type},
      $result->seller->${\$result->seller->type},
    );
    $result->update({ distance => $distance }) if defined $distance;
  }
}

sub _set_lat_long_for_result {
  my ( $self, $result ) = @_;

  my $parsed_postcode = Geo::UK::Postcode::Regex->parse($result->postcode);
  my $pc_rs = $self->app->schema->resultset('GbPostcode');

  if ( $parsed_postcode->{valid} && !$parsed_postcode->{non_geographical} ) {
    my $gb_pc = $pc_rs->find({
      outcode => $parsed_postcode->{outcode},
      incode => $parsed_postcode->{incode},
    });
    if ( $gb_pc ) {
      $result->update({
        latitude => $gb_pc->latitude,
        longitude => $gb_pc->longitude,
      });
    }
  }
}

sub _calculate_distance {
  my ( $self, $buyer, $seller ) = @_;

  my $gis = GIS::Distance->new();

  my $buyer_lat = $buyer->latitude;
  my $buyer_long = $buyer->longitude;
  my $seller_lat = $seller->latitude;
  my $seller_long = $seller->longitude;

  if ( $buyer_lat && $buyer_long 
    && $seller_lat && $seller_long ) {
    return $gis->distance( $buyer_lat, $buyer_long => $seller_lat, $seller_long )->meters;
  } else {
    print STDERR "missing lat-long for: " . $buyer->name . " or " . $seller->name . "\n";
  }
  return;
}

=head1 SYNOPSIS

  Usage: APPLICATION latlong_setup [OPTIONS]

  Options:

    none for now

=cut

1;
