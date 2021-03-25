package Pear::LocalLoop::Plugin::Currency;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $plugin, $app, $cong ) = @_;

    $app->helper(
        parse_currency => sub {
            my ( $c, $currency_string ) = @_;
            my $value;
            if ( $currency_string =~ /^£([\d.]+)/ ) {
                $value = $1 * 1;
            }
            elsif ( $currency_string =~ /^([\d.]+)/ ) {
                $value = $1 * 1;
            }
            return $value;
        }
    );

    $app->helper(
        format_currency_from_db => sub {
            my ( $c, $value ) = @_;
            return sprintf( '£%.2f', $value / 100000 );
        }
    );

    return 1;
}

1;
