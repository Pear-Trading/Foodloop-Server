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
  my $month_transaction_category_rs = $c->schema->resultset('ViewQuantisedTransactionCategory' . $driver)->search(
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
          value            => { sum => 'value' },
          category_id      => 'category_id',
          essential        => 'essential',
        }
      ],
      group_by => [ qw/ category_id quantised_weeks / ],
      order_by => { '-desc' => 'value' },
    }
  );

  my $data = { categories => {}, essentials => {} };

  for my $cat_trans ( $month_transaction_category_rs->all ) {
    my $quantised = $c->db_datetime_parser->parse_datetime($cat_trans->get_column('quantised'));
    my $days = $c->format_iso_date( $quantised ) || 0;
    my $category = $cat_trans->get_column('category_id') || 0;
    my $value = ($cat_trans->get_column('value') || 0) / 100000;
    $data->{categories}->{$days} = [] unless exists $data->{categories}->{$days};
    push @{ $data->{categories}->{$days} }, {
      days => $days,
      value => $value,
      category => $category,
    };
    next unless $cat_trans->get_column('essential');
    $data->{essentials}->{$days}->{value} += $value;
  }

  for my $day ( keys %{ $data->{categories} } ) {
    $data->{categories}->{$day} = [ sort { $b->{value} <=> $a->{value} } @{ $data->{categories}->{$day} } ];
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
