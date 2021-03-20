package Pear::LocalLoop::Controller::Api::V1::Customer::Graphs;
use Mojo::Base 'Mojolicious::Controller';

has error_messages => sub {
    return {
        graph => {
            required => { message => 'Must request graph type', status => 400 },
            in       => { message => 'Unrecognised graph type', status => 400 },
        },
    };
};

sub index {
    my $c = shift;

    my $validation = $c->validation;
    $validation->input( $c->stash->{api_json} );
    $validation->required('graph')->in(
        qw/
          total_last_week
          avg_spend_last_week
          total_last_month
          avg_spend_last_month
          /
    );

    return $c->api_validation_error if $validation->has_error;

    my $graph_sub = "graph_" . $validation->param('graph');

    unless ( $c->can($graph_sub) ) {

        # Secondary catch in case a mistake has been made
        return $c->render(
            json => {
                success => Mojo::JSON->false,
                message => $c->error_messages->{graph}->{in}->{message},
                error   => 'in',
            },
            status => $c->error_messages->{graph}->{in}->{status},
        );
    }

    return $c->$graph_sub;
}

sub graph_total_last_week  { return shift->_purchases_total_duration(7) }
sub graph_total_last_month { return shift->_purchases_total_duration(30) }

sub _purchases_total_duration {
    my ( $c, $day_duration ) = @_;

    my $duration = DateTime::Duration->new( days => $day_duration );
    my $entity   = $c->stash->{api_user}->entity;

    my $data = { labels => [], data => [] };

    my ( $start, $end ) = $c->_get_start_end_duration($duration);

    $data->{bounds} = {
        min => $c->format_iso_datetime($start),
        max => $c->format_iso_datetime($end),
    };

    while ( $start < $end ) {
        my $next_end = $start->clone->add( days => 1 );
        my $transactions =
          $entity->purchases->search_between( $start, $next_end )
          ->get_column('value')->sum || 0 * 1;
        push @{ $data->{labels} }, $c->format_iso_datetime($start);
        push @{ $data->{data} },   $transactions / 100000;
        $start->add( days => 1 );
    }

    return $c->render(
        json => {
            success => Mojo::JSON->true,
            graph   => $data,
        }
    );
}

sub graph_avg_spend_last_week { return shift->_purchases_avg_spend_duration(7) }

sub graph_avg_spend_last_month {
    return shift->_purchases_avg_spend_duration(30);
}

sub _purchases_avg_spend_duration {
    my ( $c, $day_duration ) = @_;

    my $duration = DateTime::Duration->new( days => $day_duration );
    my $entity   = $c->stash->{api_user}->entity;

    my $data = { labels => [], data => [] };

    my ( $start, $end ) = $c->_get_start_end_duration($duration);

    $data->{bounds} = {
        min => $c->format_iso_datetime($start),
        max => $c->format_iso_datetime($end),
    };

    my $dtf    = $c->schema->storage->datetime_parser;
    my $driver = $c->schema->storage->dbh->{Driver}->{Name};
    my $transaction_rs =
      $c->schema->resultset( 'ViewQuantisedTransaction' . $driver )->search(
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
                    quantised => 'quantised_days',
                    count     => \"COUNT(*)",
                    sum_value => $c->pg_or_sqlite(
                        'SUM("me"."value")', 'SUM("me"."value")',
                    ),
                    average_value => $c->pg_or_sqlite(
                        'AVG("me"."value")', 'AVG("me"."value")',
                    ),
                }
            ],
            group_by => 'quantised_days',
            order_by => { '-asc' => 'quantised_days' },
        }
      );

    for ( $transaction_rs->all ) {
        my $quantised =
          $c->db_datetime_parser->parse_datetime( $_->get_column('quantised') );
        push @{ $data->{labels} }, $c->format_iso_datetime($quantised);
        push @{ $data->{data} },
          ( $_->get_column('average_value') || 0 ) / 100000;
    }

    return $c->render(
        json => {
            success => Mojo::JSON->true,
            graph   => $data,
        }
    );
}

sub _get_start_end_duration {
    my ( $c, $duration ) = @_;
    my $end   = DateTime->today;
    my $start = $end->clone->subtract_duration($duration);
    return ( $start, $end );
}

sub pg_or_sqlite {
    my ( $c, $pg_sql, $sqlite_sql ) = @_;

    my $driver = $c->schema->storage->dbh->{Driver}->{Name};

    if ( $driver eq 'Pg' ) {
        return \$pg_sql;
    }
    elsif ( $driver eq 'SQLite' ) {
        return \$sqlite_sql;
    }
    else {
        $c->app->log->warn('Unknown Driver Used');
        return;
    }
}

1;
