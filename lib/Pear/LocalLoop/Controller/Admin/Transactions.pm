package Pear::LocalLoop::Controller::Admin::Transactions;
use Mojo::Base 'Mojolicious::Controller';

use List::Util qw/ max sum /;

has result_set => sub {
    my $c = shift;
    return $c->schema->resultset('Transaction');
};

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub index {
## use critic
    my $c = shift;

    my $pending_transaction_rs =
      $c->schema->resultset('Organisation')->search( { pending => 1 } )
      ->entity->sales;

    my $driver = $c->schema->storage->dbh->{Driver}->{Name};
    my $week_transaction_rs =
      $c->schema->resultset( 'ViewQuantisedTransaction' . $driver )->search(
        {},
        {
            select => [
                { count => 'me.value', '-as' => 'count' },
                { sum   => 'me.value', '-as' => 'sum_value' },
                'quantised_weeks',
            ],
            group_by => 'quantised_weeks',
            order_by => { '-asc' => 'quantised_weeks' },
        }
      );

    my @all_weeks = $week_transaction_rs->all;
    my $first_week_count =
      defined $all_weeks[0] ? $all_weeks[0]->get_column('count') || 0 : 0;
    my $first_week_value =
      defined $all_weeks[0]
      ? $all_weeks[0]->get_column('sum_value') / 100000 || 0
      : 0;
    my $second_week_count =
      defined $all_weeks[1] ? $all_weeks[1]->get_column('count') || 0 : 0;
    my $second_week_value =
      defined $all_weeks[1]
      ? $all_weeks[1]->get_column('sum_value') / 100000 || 0
      : 0;

    my $transaction_rs = $c->schema->resultset('Transaction');
    my $value_rs_col   = $transaction_rs->get_column('value');
    my $max_value = $value_rs_col->max / 100000                            || 0;
    my $avg_value = sprintf( '%.2f', $value_rs_col->func('AVG') / 100000 ) || 0;
    my $sum_value = $value_rs_col->sum / 100000                            || 0;
    my $count     = $transaction_rs->count                                 || 0;

    my $placeholder = 'Placeholder';
    $c->stash(
        placeholder   => $placeholder,
        pending_trans => $pending_transaction_rs->count,
        weeks         => {
            first_count  => $first_week_count,
            second_count => $second_week_count,
            first_value  => $first_week_value,
            second_value => $second_week_value,
            max          => $max_value,
            avg          => $avg_value,
            sum          => $sum_value,
            count        => $count,
        },
    );
    
    return 1;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub read {
## use critic
    my $c = shift;

    my $id = $c->param('id');

    if ( my $transaction = $c->result_set->find($id) ) {
        $c->stash( transaction => $transaction );
    }
    else {
        $c->flash( error => 'No transaction found' );
        $c->redirect_to('/admin/transactions');
    }
    
    return 1;
}

sub image {
    my $c = shift;

    my $id = $c->param('id');

    my $transaction = $c->result_set->find($id);

    if ( $transaction->proof_image ) {
        $c->reply->asset( $c->get_file_from_uuid( $transaction->proof_image ) );
    }
    else {
        $c->reply->static('image/no_transaction.jpg');
    }
    
    return 1;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
## use critic
    my $c = shift;

    my $id = $c->param('id');

    if ( my $transaction = $c->result_set->find($id) ) {
        if ( defined $transaction->category ) {
            $transaction->category->delete;
        }
        $transaction->delete;
        $c->flash( success => 'Successfully deleted transaction' );
        $c->redirect_to('/admin/transactions');
    }
    else {
        $c->flash( error => 'No transaction found' );
        $c->redirect_to('/admin/transactions');
    }
    
    return 1;
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
