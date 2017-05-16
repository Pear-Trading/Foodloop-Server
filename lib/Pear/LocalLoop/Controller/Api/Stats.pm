package Pear::LocalLoop::Controller::Api::Stats;
use Mojo::Base 'Mojolicious::Controller';

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
    today_sum => $today_sum,
    today_count => $today_count,
    week_sum => $week_sum,
    week_count => $week_count,
    month_sum => $month_sum,
    month_count => $month_count,
    user_sum => $user_sum,
    user_count => $user_count,
    global_sum => $global_sum,
    global_count => $global_count,
  });
}

1;
