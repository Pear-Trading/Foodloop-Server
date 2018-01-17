package Pear::LocalLoop::Controller::Api::Categories;
use Mojo::Base 'Mojolicious::Controller';

use List::Util qw/ max sum /;

has error_messages => sub {
  return {
    type => {
      required => { message => 'Type of Leaderboard Required', status => 400 },
      in_resultset => { message => 'Unrecognised Leaderboard Type', status => 400 },
    },
  };
};

sub post_category_list {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;

  my $duration = DateTime::Duration->new( days => 30 );
  my $end = DateTime->today;
  my $start = $end->clone->subtract_duration( $duration );

  my $data = { days => [], category => [], value => [] };

  my $dtf = $c->schema->storage->datetime_parser;
  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $month_transaction_rs = $c->schema->resultset('ViewQuantisedTransactionCategory' . $driver)->search(
    {
      purchase_time => {
        -between => [
          $dtf->format_datetime($start),
          $dtf->format_datetime($end),
        ],
      },
      buyer_id => $entity->id,
    },
    {
      columns => [
        {
          quantised        => 'quantised_days',
          count            => \"COUNT(*)",
        }
      ],
      group_by => 'quantised_days',
      order_by => { '-asc' => 'quantised_days' },
    }
  );

  for ( $transaction_rs->all ) {
    my $quantised = $c->db_datetime_parser->parse_datetime($_->get_column('quantised'));
    push @{ $data->{ days } }, ($c->format_iso_datetime( $quantised ) || 0);
    push @{ $data->{ category } }, ($_->get_column('category_id') || 0);
    push @{ $data->{ value } }, ($_->get_column('value') || 0) / 100000;
  }

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      graph => $data,
    }
  );
}

sub pg_or_sqlite {
  my ( $c, $pg_sql, $sqlite_sql ) = @_;

  my $driver = $c->schema->storage->dbh->{Driver}->{Name};

  if ( $driver eq 'Pg' ) {
    return \$pg_sql;
  } elsif ( $driver eq 'SQLite' ) {
    return \$sqlite_sql;
  } else {
    $c->app->log->warn('Unknown Driver Used');
    return undef;
  }
}

1;
