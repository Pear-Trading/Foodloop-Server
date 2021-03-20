package Pear::LocalLoop::Plugin::Minion::Job::leaderboards_recalc;
use Mojo::Base 'Pear::LocalLoop::Plugin::Minion::Job';

sub run {
    my ( $self, @args ) = @_;

    my $leaderboard_rs = $self->app->schema->resultset('Leaderboard');

    $leaderboard_rs->recalculate_all;

    return 1;
}

1;
