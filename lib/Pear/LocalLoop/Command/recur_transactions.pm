package Pear::LocalLoop::Command::recur_transactions;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

use DateTime;
use DateTime::Format::Strptime;

has description => 'Recur Transactions';

has usage => sub { shift->extract_usage };

sub run {
  my ( $self, @args ) = @_;

  my $app = $self->app;

  getopt \@args,
    'f|force' => \my $force,
    'd|date=s' => \my $date;

  unless ( defined $force ) {
    say "Will not do anything without force option";
    return;
  }

  my $date_formatter = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d'
  );

  my $datetime;

  if ( defined $date ) {

    $datetime = $date_formatter->parse_datetime($date);

    unless ( defined $datetime ) {
      say "Unrecognised date format, please use 'YYYY-MM-DD' Format";
      return;
    }
  } else {
    $datetime = DateTime->today;
  }

  my $match_date_day = $app->format_iso_date($datetime->clone->subtract( days => 1 ));
  my $match_date_week = $app->format_iso_date($datetime->clone->subtract( weeks => 1 ));
  my $match_date_fortnight = $app->format_iso_date($datetime->clone->subtract( weeks => 2 ));
  my $match_date_month = $app->format_iso_date($datetime->clone->subtract( months => 1 ));
  my $match_date_quarter = $app->format_iso_date($datetime->clone->subtract( months => 3));

  my $schema = $app->schema;
  my $dtf = $schema->storage->datetime_parser;
  my $recur_rs = $schema->resultset('TransactionRecurring');

  for my $recur_result ( $recur_rs->all ) {

    my $start_time_dt;
    if ( defined $recur_result->last_updated ) {
      $start_time_dt = $recur_result->last_updated;
    } else {
      $start_time_dt = $recur_result->start_time;
    }
    my $start_time = $app->format_iso_date($start_time_dt);
    my $recurring_period = $recur_result->recurring_period;

    if ( $recurring_period eq 'daily' ) {
      next unless $start_time eq $match_date_day;
      say "matched recurring transaction ID " . $recur_result->id . " to daily";
    } elsif ( $recurring_period eq 'weekly' ) {
      next unless $start_time eq $match_date_week;
      say "matched recurring transaction ID " . $recur_result->id . " to weekly";
    } elsif ( $recurring_period eq 'fortnightly' ) {
      next unless $start_time eq $match_date_fortnight;
      say "matched recurring transaction ID " . $recur_result->id . " to fortnightly";
    } elsif ( $recurring_period eq 'monthly' ) {
      next unless $start_time eq $match_date_month;
      say "matched recurring transaction ID " . $recur_result->id . " to monthly";
    } elsif ( $recurring_period eq 'quarterly' ) {
      next unless $start_time eq $match_date_quarter;
      say "matched recurring transaction ID " . $recur_result->id . " to quarterly";
    } else {
      say "Invalid recurring time period given";
      return;
    }

    my $now = DateTime->now();
    my $purchase_time = DateTime->new(
      year => $now->year,
      month => $now->month,
      day => $now->day,
      hour => $start_time_dt->hour,
      minute => $start_time_dt->minute,
      second => $start_time_dt->second,
      time_zone => 'UTC',
    );
    my $category = $recur_result->category_id;
    my $essential = $recur_result->essential;
    my $distance = $recur_result->distance;

    my $new_transaction = $schema->resultset('Transaction')->create({
      buyer_id => $recur_result->buyer_id,
      seller_id => $recur_result->seller_id,
      value => $recur_result->value,
      purchase_time => $app->format_db_datetime($purchase_time),
      distance => $distance,
      essential => ( defined $essential ? $essential : 0 ),
    });

    unless ( defined $new_transaction ) {
      say "Error Adding Transaction";
      return;
    }

    if ( defined $category ) {
      $schema->resultset('TransactionCategory')->create({
        category_id => $category,
        transaction_id => $new_transaction->id,
      });
    }

    $recur_result->update({ last_updated => $purchase_time });

  }
}

=head1 SYNOPSIS

  Usage: APPLICATION recur_transactions [OPTIONS]

  Options:

    -f, --force   Actually insert the data
    -d, --date    Date to recur the transactions on

=cut

1;
