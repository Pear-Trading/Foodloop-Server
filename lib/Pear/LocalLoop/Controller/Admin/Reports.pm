package Pear::LocalLoop::Controller::Admin::Reports;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw/ encode_json /;

sub transaction_data {
  my $c = shift;

  my $quantised_column = 'quantised_hours';
  if ( defined $c->param('scale') && $c->param('scale') eq 'days' ) {
    $quantised_column = 'quantised_days';
  }

  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $transaction_rs = $c->schema->resultset('ViewQuantisedTransaction' . $driver)->search(
    {},
    {
      columns => [
        {
          quantised        => $quantised_column,
          count            => $c->pg_or_sqlite(
                                'count',
                                "COUNT(*)",
                              ),
          sum_distance     => $c->pg_or_sqlite(
                                'SUM("me"."distance")',
                                'SUM("me"."distance")',
                              ),
          average_distance => $c->pg_or_sqlite(
                                'AVG("me"."distance")',
                                'AVG("me"."distance")',
                              ),
          sum_value        => $c->pg_or_sqlite(
                                'SUM("me"."value")',
                                'SUM("me"."value")',
                              ),
          average_value    => $c->pg_or_sqlite(
                                'AVG("me"."value")',
                                'AVG("me"."value")',
                              ),
        }
      ],
      group_by => $quantised_column,
      order_by => { '-asc' => $quantised_column },
    }
  );

  my $transaction_data = [
    map{
      my $quantised = $c->db_datetime_parser->parse_datetime($_->get_column('quantised'));
      {
        sum_value         => ($_->get_column('sum_value') || 0) * 1,
        sum_distance      => ($_->get_column('sum_distance') || 0) * 1,
        average_value     => ($_->get_column('average_value') || 0) * 1,
        average_distance  => ($_->get_column('average_distance') || 0) * 1,
        count             => $_->get_column('count'),
        quantised         => $c->format_iso_datetime($quantised),
      }
    } $transaction_rs->all
  ];

  $c->respond_to(
    json => { json => { data => $transaction_data } },
    html => { transaction_rs => encode_json( $transaction_data ) },
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
