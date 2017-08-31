package Pear::LocalLoop::Schema::ResultSet::Transaction;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use DateTime;

sub search_between {
  my ( $self, $from, $to ) = @_;

  my $dtf = $self->result_source->schema->storage->datetime_parser;
  return $self->search({
    purchase_time => {
      -between => [
        $dtf->format_datetime($from),
        $dtf->format_datetime($to),
      ],
    },
  });
}

sub search_before {
  my ( $self, $date ) = @_;

  my $dtf = $self->result_source->schema->storage->datetime_parser;
  return $self->search({
    purchase_time => { '<' => $dtf->format_datetime( $date ) },
  });
}

sub today_rs {
  my ( $self ) = @_;

  my $today = DateTime->today();
  return $self->search_between( $today, $today->clone->add( days => 1 ) );
}

sub week_rs {
  my ( $self ) = @_;

  my $today = DateTime->today();
  return $self->search_between( $today->clone->subtract( days => 7 ), $today );
}

sub month_rs {
  my ( $self ) = @_;

  my $today = DateTime->today();
  return $self->search_between( $today->clone->subtract( days => 30 ), $today );
}

1;
