package Pear::LocalLoop::Schema::ResultSet::Leaderboard;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use DateTime;

sub get_latest {
  my $self = shift;
  my $type = shift;

  my $type_result = $self->find_by_type( $type );

  return undef unless defined $type_result;

  my $latest = $type_result->search_related('sets', {}, {
    order_by => { -desc => 'date' },
  })->first;

  return $latest;
}

sub create_new {
  my $self = shift;
  my $type = shift;
  my $date = shift;

  my $type_result = $self->find_by_type($type);

  return undef unless $type_result;

  return $type_result->create_new($date);
}

sub find_by_type {
  my $self = shift;
  my $type = shift;

  return $self->find({ type => $type });
}

sub recalculate_all {
  my $self = shift;

  for my $leaderboard_result ( $self->all ) {
    my $lb_type = $leaderboard_result->type;
    if ( $lb_type =~ /^daily/ ) {

      # Recalculating a daily set. This is calculated from the start of the
      # day, so we need yesterdays date:
      my $date = DateTime->today->subtract( days => 1 );
      $self->_recalculate_leaderboard( $leaderboard_result, $date, 'days' );

    } elsif ( $lb_type =~ /^weekly/ ) {

      # Recalculating a weekly set. This is calculated from a Monday, of the
      # week before.
      my $date = DateTime->today->truncate( to => 'week' )->subtract( weeks => 1 );
      $self->_recalculate_leaderboard( $leaderboard_result, $date, 'weeks' );

    } elsif ( $lb_type =~ /^monthly/ ) {

      # Recalculate a monthly set. This is calculated from the first of the
      # month, for the month before.
      my $date = DateTime->today->truncate( to => 'month' )->subtract( months => 1);
      $self->_recalculate_leaderboard( $leaderboard_result, $date, 'months' );

    } elsif ( $lb_type =~ /^all_time/ ) {

      # Recalculate for an all time set. This is calculated similarly to
      # daily, but is calculated from an end time.
      my $date = DateTime->today;
      $self->_recalculate_leaderboard( $leaderboard_result, $date, 'days' );

    } else {
      warn "Unrecognised Set";
    }
  }
}

sub _recalculate_leaderboard {
  my ( $self, $lb_result, $date, $diff ) = @_;

  $self->result_source->schema->txn_do( sub {
    $lb_result->sets->related_resultset('values')->delete_all;
    $lb_result->sets->delete_all;
    $lb_result->create_new($date->clone->subtract( $diff => 1 ));
    $lb_result->create_new($date);
  });
}

1;
