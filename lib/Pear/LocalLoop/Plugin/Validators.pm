package Pear::LocalLoop::Plugin::Validators;
use Mojo::Base 'Mojolicious::Plugin';

use Email::Valid;
use Geo::UK::Postcode;

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

  $app->validator->add_check( not_in_resultset => sub {
    my ( $validation, $name, $value, $key, $rs ) = @_;
    return $rs->search({ $key => $value })->count ? 1 : undef;
  });

  $app->validator->add_check( postcode => sub {
    my ( $validation, $name, $value ) = @_;
    return Geo::UK::Postcode->new( $value )->valid ? undef : 1;
  });
}

1;
