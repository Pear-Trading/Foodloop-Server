package Pear::LocalLoop::Command::dev_transactions;

use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

use DateTime;
use DateTime::Format::Strptime;

has description => 'Input Dev Transaction';

has usage => sub { shift->extract_usage };

sub run {
    my ( $self, @args ) = @_;

    getopt \@args,
      'f|force'    => \my $force,
      'd|date=s'   => \my $date,
      'n|number=i' => \my $number,
      'c|count=i'  => \my $count;

    unless ( defined $force ) {
        say "Will not do anything without force option";
        return;
    }

    if ( ( defined( $ENV{MOJO_MODE} ) && $ENV{MOJO_MODE} eq 'production' )
        || $self->app->mode eq 'production' )
    {
        say "Will not run dev data fixtures in production!";
        return;
    }

    my $date_formatter =
      DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' );

    my $datetime;

    if ( defined $date ) {

        $datetime = $date_formatter->parse_datetime($date);

        unless ( defined $datetime ) {
            say "Unrecognised date format, please use 'YYYY-MM-DD' Format";
            return;
        }
    }
    else {
        $datetime = DateTime->today;
    }

    my $schema = $self->app->schema;

    my $user_rs = $schema->resultset('User');

    my $organisation_rs = $user_rs->search( { customer_id => undef } );

    my $dtf = $schema->storage->datetime_parser;

    my @organisations = $organisation_rs->all;

    unless ( defined $number ) {
        $number = 1;
    }

    unless ( defined $count ) {
        $count = 0;
    }

    for my $day_sub ( 0 .. $count ) {
        $datetime->subtract( days => 1 );
        for ( 1 .. $number ) {
            for my $user_result ( $user_rs->all ) {
                $user_result->create_related(
                    'transactions',
                    {
                        seller_id =>
                          $organisations[ int( rand($#organisations) ) ]
                          ->organisation_id,
                        value         => int( rand(9999) ) / 100,
                        proof_image   => 'a',
                        purchase_time => $dtf->format_datetime(
                            $datetime->clone->add(
                                minutes => int( rand(1440) )
                            )
                        ),
                    }
                );
            }
        }
    }

    return 1;
}

=head1 SYNOPSIS

  Usage: APPLICATION dev_transactions [OPTIONS]

  Options:

    -f, --force   Actually insert the data
    -d, --date    Date to create the transactions on

=cut

1;
