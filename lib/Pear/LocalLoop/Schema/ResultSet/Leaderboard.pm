package Pear::LocalLoop::Schema::ResultSet::Leaderboard;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

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

1;
