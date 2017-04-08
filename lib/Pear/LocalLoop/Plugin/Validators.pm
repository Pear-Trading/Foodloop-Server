package Pear::LocalLoop::Plugin::Validators;
use Mojo::Base 'Mojolicious::Plugin';

use Email::Valid;

sub register {
  my ( $plugin, $app, $conf ) = @_;

  $app->validator->add_check( email => sub {
    my ( $validation, $name, $email ) = @_;
    return Email::Valid->address( $email ) ? undef : 1;
  });
  $app->validator->add_check( in_resultset => sub {
    my ( $validation, $name, $value, $key, $rs ) = @_;
    return $rs->search({ $key => $value })->count ? undef : 1;
  });
}

1;
