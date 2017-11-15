package Pear::LocalLoop::Plugin::Currency;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app, $cong ) = @_;

  $app->helper( parse_currency => sub {
    my ( $c, $currency_string ) = @_;
    my $value;
    if ( $currency_string =~ /^£([\d.]+)/ ) {
      $value = $1 * 1;
    }
    return $value;
  });
}

1;
