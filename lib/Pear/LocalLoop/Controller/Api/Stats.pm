package Pear::LocalLoop::Controller::Api::Stats;
use Mojo::Base 'Mojolicious::Controller';

use List::Util qw/ first /;

has error_messages => sub {
  return {
    type => {
      required => { message => 'Type of Leaderboard Required', status => 400 },
      in_resultset => { message => 'Unrecognised Leaderboard Type', status => 400 },
    },
  };
};

sub post_index {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $today_rs = $user->transactions->today_rs;
  my $today_sum = $today_rs->get_column('value')->sum;
  my $today_count = $today_rs->count;

  my $week_rs = $user->transactions->week_rs;
  my $week_sum = $week_rs->get_column('value')->sum;
  my $week_count = $week_rs->count;

  my $month_rs = $user->transactions->month_rs;
  my $month_sum = $month_rs->get_column('value')->sum;
  my $month_count = $month_rs->count;

  my $user_rs = $user->transactions;
  my $user_sum = $user_rs->get_column('value')->sum;
  my $user_count = $user_rs->count;

  my $global_rs = $c->schema->resultset('Transaction');
  my $global_sum = $global_rs->get_column('value')->sum;
  my $global_count = $global_rs->count;

  return $c->render( json => {
    success => Mojo::JSON->true,
    today_sum => $today_sum || 0,
    today_count => $today_count,
    week_sum => $week_sum || 0,
    week_count => $week_count,
    month_sum => $month_sum || 0,
    month_count => $month_count,
    user_sum => $user_sum || 0,
    user_count => $user_count,
    global_sum => $global_sum || 0,
    global_count => $global_count,
  });
}

sub post_leaderboards {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $leaderboard_rs = $c->schema->resultset('Leaderboard');

  $validation->required('type')->in_resultset( 'type', $leaderboard_rs );

  return $c->api_validation_error if $validation->has_error;

  my $today_board = $leaderboard_rs->get_latest( $validation->param('type') );

  my $today_values = $today_board->values->search(
    {},
    {
      order_by => { -desc => 'me.value' },
      columns => [
        qw/
          me.value
          me.trend
          me.user_id
        /,
        { display_name => 'customer.display_name' },
      ],
      join => { user => 'customer' },
    },
  );
  $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

  my @leaderboard_array = $today_values->all;

  my $current_user_index = first { $leaderboard_array[$_]->{user_id} == $c->stash->{api_user}->id } 0..$#leaderboard_array;

  # Dont leak user id's
  map { delete $_->{user_id} } @leaderboard_array;

  return $c->render( json => {
    success => Mojo::JSON->true,
    leaderboard => [ @leaderboard_array ],
    user_position => $current_user_index,
  });
}

1;
