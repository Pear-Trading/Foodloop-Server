package Pear::LocalLoop::Controller::Api::Categories;
use Mojo::Base 'Mojolicious::Controller';

use List::Util qw/ max /;

sub post_category_list {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;

  my $duration = DateTime::Duration->new( days => 28 );
  my $end = DateTime->today;
  my $start = $end->clone->subtract_duration( $duration );

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
          quantised        => 'quantised_weeks',
          value            => 'value',
          category_id      => 'category_id',
        }
      ],
      group_by => [ qw/ category_id quantised_weeks / ],
      order_by => { '-desc' => 'value' },
    }
  );

  my $data = {};

  for ( $month_transaction_rs->all ) {
    my $quantised = $c->db_datetime_parser->parse_datetime($_->get_column('quantised'));
    my $days = $c->format_iso_date( $quantised ) || 0;
    my $category = $_->get_column('category_id') || 0;
    my $value = ($_->get_column('value') || 0) / 100000;
    $data->{$days} = [] unless exists $data->{$days};
    push @{ $data->{$days} }, {
      days => $days,
      value => $value,
      category => $category,
    };
  }

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      data => $data,
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
