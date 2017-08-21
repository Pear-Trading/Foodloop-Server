package Pear::LocalLoop::Schema::Result::Leaderboard;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use DateTime;

__PACKAGE__->table("leaderboards");

__PACKAGE__->add_columns(
  "id" => {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
  "type" => {
    data_type => "varchar",
    size => 255,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint(["type"]);

__PACKAGE__->has_many(
  "sets",
  "Pear::LocalLoop::Schema::Result::LeaderboardSet",
  { "foreign.leaderboard_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub create_new {
  my $self = shift;
  my $start = shift;

  my $type = $self->type;

  if ( $type eq 'daily_total' ) {
    return $self->_create_total_set( $start, $start->clone->add( days => 1 ) );
  } elsif ( $type eq 'weekly_total' ) {
    return $self->_create_total_set( $start, $start->clone->add( days => 7 ) );
  } elsif ( $type eq 'monthly_total' ) {
    return $self->_create_total_set( $start, $start->clone->add( months => 1 ) );
  } elsif ( $type eq 'all_time_total' ) {
    return $self->_create_total_all_time( $start );
  } elsif ( $type eq 'daily_count' ) {
    return $self->_create_count_set( $start, $start->clone->add( days => 1 ) );
  } elsif ( $type eq 'weekly_count' ) {
    return $self->_create_count_set( $start, $start->clone->add( days => 7 ) );
  } elsif ( $type eq 'monthly_count' ) {
    return $self->_create_count_set( $start, $start->clone->add( months => 1 ) );
  } elsif ( $type eq 'all_time_count' ) {
    return $self->_create_count_all_time( $start );
  }
  warn "Unrecognised type";
  return $self;
}

sub _get_customer_rs {
  my $self = shift;
  return $self->result_source->schema->resultset('User')->search({
    organisation_id => undef,
  });
}

sub _set_position_and_trend {
  my ( $self, @leaderboard ) = @_;

  # Sort numerically descending
  @leaderboard = sort { $b->{value} <=> $a->{value} } @leaderboard;

  my $position = 0;

  my $previous_board = $self->get_latest;

  if ( defined $previous_board ) {
    $previous_board = $previous_board->values;
  }

  for my $lb_val ( @leaderboard ) {
    $position++;
    $lb_val->{position} = $position;

    my $previous_value;

    if ( defined $previous_board ) {
      $previous_value = $previous_board->find({ user_id => $lb_val->{user_id} });
    }

    my $trend;

    if ( ! defined $previous_value ) {
      $trend = 0;
    } elsif ( $previous_value->position > $position ) {
      $trend = -1;
    } elsif ( $previous_value->position < $position ) {
      $trend = 1;
    } else {
      $trend = 0;
    }

    $lb_val->{trend} = $trend;
  }

  return @leaderboard;
}

sub _create_total_set {
  my ( $self, $start, $end ) = @_;

  my $user_rs = $self->_get_customer_rs;

  my @leaderboard;

  while ( my $user_result = $user_rs->next ) {
    my $transaction_rs = $user_result->transactions->search_between( $start, $end );

    my $transaction_sum = $transaction_rs->get_column('value')->sum;

    push @leaderboard, {
      user_id => $user_result->id,
      value => $transaction_sum || 0,
    };
  }

  @leaderboard = $self->_set_position_and_trend(@leaderboard);

  $self->create_related(
    'sets',
    {
      date => $start,
      values => \@leaderboard,
    },
  );

  return $self;
}

sub _create_count_set {
  my ( $self, $start, $end ) = @_;

  my $user_rs = $self->_get_customer_rs;

  my @leaderboard;

  while ( my $user_result = $user_rs->next ) {
    my $transaction_rs = $user_result->transactions->search_between( $start, $end );

    my $transaction_count = $transaction_rs->count;

    push @leaderboard, {
      user_id => $user_result->id,
      value => $transaction_count || 0,
    };
  }

  @leaderboard = $self->_set_position_and_trend(@leaderboard);

  $self->create_related(
    'sets',
    {
      date => $start,
      values => \@leaderboard,
    },
  );

  return $self;
}

sub _create_total_all_time {
  my ( $self, $end ) = @_;

  my $user_rs = $self->_get_customer_rs;
 
  my @leaderboard;

  while ( my $user_result = $user_rs->next ) {
    my $transaction_rs = $user_result->transactions->search_before( $end );

    my $transaction_sum = $transaction_rs->get_column('value')->sum;

    push @leaderboard, {
      user_id => $user_result->id,
      value => $transaction_sum || 0,
    };
  }

  @leaderboard = $self->_set_position_and_trend(@leaderboard);

  $self->create_related(
    'sets',
    {
      date => $end,
      values => \@leaderboard,
    },
  );

  return $self;
}

sub _create_count_all_time {
  my ( $self, $end ) = @_;

  my $user_rs = $self->_get_customer_rs;

  my @leaderboard;

  while ( my $user_result = $user_rs->next ) {
    my $transaction_rs = $user_result->transactions->search_before( $end );

    my $transaction_count = $transaction_rs->count;

    push @leaderboard, {
      user_id => $user_result->id,
      value => $transaction_count || 0,
    };
  }

  @leaderboard = $self->_set_position_and_trend(@leaderboard);

  $self->create_related(
    'sets',
    {
      date => $end,
      values => \@leaderboard,
    },
  );

  return $self;
}

sub get_latest {
  my $self = shift;

  my $latest = $self->search_related('sets', {}, {
    order_by => { -desc => 'date' },
  })->first;

  return $latest;
}

1;
