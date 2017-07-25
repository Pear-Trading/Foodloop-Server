package Pear::LocalLoop::Plugin::Validators;
use Mojo::Base 'Mojolicious::Plugin';

use Email::Valid;
use Geo::UK::Postcode::Regex qw/ is_valid_pc /;
use Scalar::Util qw/ looks_like_number /;
use File::Basename qw/ fileparse /;
use DateTime::Format::Strptime;
use Try::Tiny;

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
    return is_valid_pc( $value ) ? undef : 1;
  });

  $app->validator->add_check( number => sub {
    my ( $validation, $name, $value ) = @_;
    return looks_like_number( $value ) ? undef : 1;
  });

  $app->validator->add_check( gt_num => sub {
    my ( $validation, $name, $value, $check ) = @_;
    return $value > $check ? undef : 1;
  });

  $app->validator->add_check( lt_num => sub {
    my ( $validation, $name, $value, $check ) = @_;
    return $value < $check ? undef : 1;
  });

  $app->validator->add_check( filetype => sub {
    my ( $validation, $name, $value, $filetype ) = @_;
    my ( undef, undef, $extension ) = fileparse $value->filename, qr/\.[^.]*/;
    $extension =~ s/^\.//;
    return $app->types->type($extension) eq $filetype ? undef : 1;
  });

  $app->validator->add_check( is_iso_datetime => sub {
    my ( $validation, $name, $value ) = @_;
    $value = $app->datetime_formatter->parse_datetime( $value );
    return defined $value ? undef : 1;
  });
}

1;
