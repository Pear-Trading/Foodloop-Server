package Pear::LocalLoop::Plugin::Datetime;
use Mojo::Base 'Mojolicious::Plugin';

use DateTime::Format::Strptime;

sub register {
  my ( $plugin, $app, $conf ) = @_;

  $app->helper( iso_datetime_parser => sub {
    return DateTime::Format::Strptime->new( pattern => '%Y-%m-%dT%H:%M:%S.%3N%z' );
  });

  $app->helper( iso_date_parser => sub {
    return DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' );
  });

  $app->helper( parse_iso_date => sub {
    my ( $c, $date_string ) = @_;
    return $c->iso_date_parser->parse_datetime(
      $date_string,
    );
  });

  $app->helper( format_iso_date => sub {
    my ( $c, $datetime_obj ) = @_;
    return $c->iso_date_parser->format_datetime(
      $datetime_obj,
    );
  });

  $app->helper( parse_iso_datetime => sub {
    my ( $c, $date_string ) = @_;
    return $c->iso_datetime_parser->parse_datetime(
      $date_string,
    );
  });

  $app->helper( format_iso_datetime => sub {
    my ( $c, $datetime_obj ) = @_;
    return $c->iso_datetime_parser->format_datetime(
      $datetime_obj,
    );
  });

  $app->helper( db_datetime_parser => sub {
    return shift->schema->storage->datetime_parser;
  });

  $app->helper( format_db_datetime => sub {
    my ( $c, $datetime_obj ) = @_;
    $datetime_obj->set_time_zone('UTC');
    return $c->db_datetime_parser->format_datetime(
      $datetime_obj,
    );
  });

}

1;
