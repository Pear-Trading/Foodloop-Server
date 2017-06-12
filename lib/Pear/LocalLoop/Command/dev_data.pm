package Pear::LocalLoop::Command::dev_data;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

has description => 'Input Dev Data';

has usage => sub { shift->extract_usage };

sub run {
  my ( $self, @args ) = @_;

  getopt \@args,
    'f|force' => \my $force;

  unless ( defined $force ) {
    say "Will not do anything without force option";
    return;
  }

  if ( $ENV{MOJO_MODE} eq 'production' || $self->app->mode eq 'production' ) {
    say "Will not run dev data fixtures in production!";
    return;
  }

  my $schema = $self->app->schema;

  $schema->resultset('AgeRange')->populate([
    [ qw/ string / ],
    [ '20-35' ],
    [ '35-50' ],
    [ '50+' ],
  ]);

  $schema->resultset('Leaderboard')->populate([
    [ qw/ name type / ],
    [ 'Daily Total', 'daily_total' ],
    [ 'Daily Count', 'daily_count' ],
    [ 'Weekly Total', 'weekly_total' ],
    [ 'Weekly Count', 'weekly_count' ],
    [ 'Monthly Total', 'monthly_total' ],
    [ 'Monthly Count', 'monthly_count' ],
    [ 'All Time Total', 'all_time_total' ],
    [ 'All Time Count', 'all_time_count' ],
  ]);

  $schema->resultset('User')->create({
    email => 'test@example.com',
    password => 'abc123',
    customer => {
      full_name => 'Test User',
      display_name => 'Test User',
      age_range_id => 1,
      postcode => 'LA1 1AA',
    },
    administrator => {},
  });

  $schema->resultset('User')->create({
    email => 'test2@example.com',
    password => 'abc123',
    customer => {
      full_name => 'Test User 2',
      display_name => 'Test User 2',
      age_range_id => 1,
      postcode => 'LA1 1AA',
    },
  });

  $schema->resultset('User')->create({
    email => 'test3@example.com',
    password => 'abc123',
    customer => {
      full_name => 'Test User 3',
      display_name => 'Test User 3',
      age_range_id => 1,
      postcode => 'LA1 1AA',
    },
  });

  $schema->resultset('User')->create({
    email       => 'testorg@example.com',
    password    => 'abc123',
    organisation => {
      name        => 'Test Org',
      street_name => 'Test Street',
      town        => 'Lancaster',
      postcode    => 'LA1 1AA',
    },
  });
}

=head1 SYNOPSIS

  Usage: APPLICATION dev_data [OPTIONS]

  Options:

    -f, --force   Actually insert the data

=cut

1;
