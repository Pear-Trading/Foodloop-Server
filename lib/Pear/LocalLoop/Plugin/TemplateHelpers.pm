package Pear::LocalLoop::Plugin::TemplateHelpers;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $plugin, $app, $conf ) = @_;

    $app->helper(
        truncate_text => sub {
            my ( $c, $string, $length ) = @_;
            if ( length $string < $length ) {
                return $string;
            }
            else {
                return substr( $string, 0, $length - 3 ) . '...';
            }
        }
    );

}

1;
