package Pear::LocalLoop::Command::leaderboard;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

has description => 'Build leaderboards';

has usage => sub { shift->extract_usage };

sub run {
    my ( $self, @args ) = @_;

    getopt \@args,
      't|type=s' => \my $type,
      'l|list'   => \my $list,
      'd|date=s' => \my $date;

    my $leaderboard_rs = $self->app->schema->resultset('Leaderboard');

    if ( defined $list ) {
        say sprintf( '%20s : %20s', 'Type', 'Name' );
        for my $leaderboard ( $leaderboard_rs->all ) {
            say
              sprintf( '%20s : %20s', $leaderboard->type, $leaderboard->name );
        }
        return;
    }

    if ( defined $type ) {
        my $leaderboard = $leaderboard_rs->find( { type => $type } );

        unless ( defined $leaderboard ) {
            say "Unknown Leaderboard Type";
            return;
        }

        if ( defined $date ) {
            say "Creating leaderboard of type $type with date $date";

            my $date_formatter =
              DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' );

            my $datetime = $date_formatter->parse_datetime($date);

            unless ( defined $datetime ) {
                say "Unrecognised date format, please use 'YYYY-MM-DD' Format";
                return;
            }

            my $dtf = $self->app->schema->storage->datetime_parser;
            my $existing_leaderboard_set = $leaderboard->search_related(
                'sets',
                {
                    date => $dtf->format_datetime($datetime),
                }
            )->first;

            if ( defined $existing_leaderboard_set ) {
                $existing_leaderboard_set->values->delete_all;
                $existing_leaderboard_set->delete;
            }

            $leaderboard->create_new($datetime);

            say "Done";
        }
        else {
            say 'Leaderboards of type ' . $type . ' available:';
            for my $set ( $leaderboard->sets->all ) {
                say $set->date;
            }
        }
    }
}

=head1 SYNOPSIS

  Usage: APPLICATION leaderboard [OPTIONS]

  Options:

    -l, --list List all leaderboard types
    -t, --type Leaderboard type to create
    -d, --date Start Date (in YYYY-MM-DD format)

=cut

1;
