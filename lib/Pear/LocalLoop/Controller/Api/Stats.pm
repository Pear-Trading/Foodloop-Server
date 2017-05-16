package Pear::LocalLoop::Controller::Api::Stats;
use Mojo::Base 'Mojolicious::Controller';

sub post_today {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $today_rs = $user->transactions->today_rs;
  my $today_sum = $today_rs->get_column('value')->sum;
  my $today_count = $today_rs->count;

  return $c->render( json => {
    success => Mojo::JSON->true,
    today_sum => $today_sum,
    today_count => $today_count,
    today_avg => $today_sum / $today_count,
  });

}

1;
