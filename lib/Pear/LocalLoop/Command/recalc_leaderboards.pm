package Pear::LocalLoop::Command::recalc_leaderboards;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

has description => 'Build All leaderboards';

has usage => sub { shift->extract_usage };

sub run {
    my ( $self, @args ) = @_;

    my $leaderboard_rs = $self->app->schema->resultset('Leaderboard');

    $leaderboard_rs->recalculate_all;
}

=head1 SYNOPSIS

  Usage: APPLICATION recalc_leaderboards

  Recalculates ALL leaderboards.

=cut

1;
