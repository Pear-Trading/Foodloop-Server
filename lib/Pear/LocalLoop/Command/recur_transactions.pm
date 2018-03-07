package Pear::LocalLoop::Command::recur_transactions;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

use DateTime;
use DateTime::Format::Strptime;

has description => 'Recur Transactions';

has usage => sub { shift->extract_usage };

sub run {
  my ( $self, @args ) = @_;

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

  my $schema = $self->app->schema;
  my $dtf = $schema->storage->datetime_parser;
  my $recur_rs = $schema->resultset('TransactionRecurring');
  my $org_rs = $c->schema->resultset('Organisation');

  for my $recur_result ( $recur_rs->all ) {

    my $last_updated = $dtf->format_iso_date($recur_result->last_updated);
    my $recurring_period = $recur_result->recurring_period;

    if ( $recurring_period = 'daily' ) {
      my $match_date = $datetime->subtract( days => 1 );
      next unless $last_updated = $match_date;
    } elsif { $recurring_period = 'weekly' } {
      my $match_date = $datetime->subtract( weeks => 1 );
      next unless $last_updated = $match_date;
    } elsif { $recurring_period = 'fortnightly' } {
      my $match_date = $datetime->subtract( weeks => 2 );
      next unless $last_updated = $match_date;
    } elsif { $recurring_period = 'monthly' } {
      my $match_date = $datetime->subtract( months => 1 );
      next unless $last_updated = $match_date;
    } elsif { $recurring_period = 'quarterly' } {
      my $match_date = $datetime->subtract( months => 3 );
      next unless $last_updated = $match_date;
    } else {
      say "Invalid recurring time period given";
      return;
    }

    my $user_id = $recur_result->buyer_id;
    my $organisation = $org_rs->find( entity_id => $recur_result->seller_id );
    my $transaction_value = $recur_result->value;
    my $purchase_time = DateTime->now();
    my $category = $recur_result->category_id;
    my $essential = $recur_result->essential;
    my $distance = $c->get_distance_from_coords( $user_id->type_object, $organisation );

    my $new_transaction = $organisation->entity->create_related(
      'sales',
      {
        buyer => $user_id,
        value => $transaction_value,
        purchase_time => $c->format_db_datetime($purchase_time),
        distance => $distance,
        essential => ( defined $essential ? $essential : 0 ),
      }
    );

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
