package Pear::LocalLoop::Controller::Api::Stats;
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

sub post_index {
  my $c = shift;

  my $user = $c->stash->{api_user}->entity;

  my $today_rs = $user->purchases->today_rs;
  my $today_sum = $today_rs->get_column('value')->sum || 0;
  my $today_count = $today_rs->count;

  my $week_rs = $user->purchases->week_rs;
  my $week_sum = $week_rs->get_column('value')->sum || 0;
  my $week_count = $week_rs->count;

  my $month_rs = $user->purchases->month_rs;
  my $month_sum = $month_rs->get_column('value')->sum || 0;
  my $month_count = $month_rs->count;

  my $user_rs = $user->purchases;
  my $user_sum = $user_rs->get_column('value')->sum || 0;
  my $user_count = $user_rs->count;

  my $global_rs = $c->schema->resultset('Transaction');
  my $global_sum = $global_rs->get_column('value')->sum || 0;
  my $global_count = $global_rs->count;

  my $leaderboard_rs = $c->schema->resultset('Leaderboard');
  my $monthly_board = $leaderboard_rs->get_latest( 'monthly_total' );
  my $monthly_values = $monthly_board->values;
  my $current_user_position = $monthly_values ? $monthly_values->find({ entity_id => $user->id }) : undef;

  return $c->render( json => {
    success => Mojo::JSON->true,
    today_sum => $today_sum / 100000,
    today_count => $today_count,
    week_sum => $week_sum / 100000,
    week_count => $week_count,
    month_sum => $month_sum / 100000,
    month_count => $month_count,
    user_sum => $user_sum / 100000,
    user_count => $user_count,
    global_sum => $global_sum / 100000,
    global_count => $global_count,
    user_position => defined $current_user_position ? $current_user_position->position : 0,
  });
}

sub post_customer {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;

  my $duration_weeks = DateTime::Duration->new( weeks => 7 );
  my $end = DateTime->today;
  my $start_weeks = $end->clone->subtract_duration( $duration_weeks );

  my $dtf = $c->schema->storage->datetime_parser;
  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $week_transaction_rs = $c->schema->resultset('ViewQuantisedTransaction' . $driver)->search(
    {
      purchase_time => {
        -between => [
          $dtf->format_datetime($start_weeks),
          $dtf->format_datetime($end),
        ],
      },
      buyer_id => $entity->id,
    },
    {
      columns => [
        {
          quantised        => 'quantised_weeks',
          count            => \"COUNT(*)",
        }
      ],
      group_by => 'quantised_weeks',
      order_by => { '-asc' => 'quantised_weeks' },
    }
  );

  my @all_weeks = $week_transaction_rs->all;
  my $first = defined $all_weeks[0] ? $all_weeks[0]->get_column('count') || 0 : 0;
  my $second = defined $all_weeks[1] ? $all_weeks[1]->get_column('count') || 0 : 0;
  my $max = max( map { $_->get_column('count') } @all_weeks );
  my $sum = sum( map { $_->get_column('count') } @all_weeks );
  my $count = $week_transaction_rs->count;

  my $weeks = {
    first => $first,
    second => $second,
    max => $max,
    sum => $sum,
    count => $count,
  };

  my $sectors = { sectors => [], purchases => [] };

  my $sector_purchase_rs = $entity->purchases->search({},
  {
    join => { 'seller' => 'organisation' },
    columns => {
      sector => "organisation.sector",
      count            => \"COUNT(*)",
    },
    group_by => "organisation.sector",
    order_by => { '-desc' => $c->pg_or_sqlite('count',"COUNT(*)",)},
  }
  );

  for ( $sector_purchase_rs->all ) {
    push @{ $sectors->{ sectors } }, $_->get_column('sector');
    push @{ $sectors->{ purchases } }, ($_->get_column('count') || 0);
  }

  my $data = { cat_total => {}, categories => {}, essentials => {} };

  my $purchase_rs = $entity->purchases;

  my $purchase_no_essential_rs = $purchase_rs->search({
    "me.essential" => 1,
  });

  $data->{essentials} = {
    purchase_no_total => $purchase_rs->count,
    purchase_no_essential_total => $purchase_no_essential_rs->count,
  };

  my $duration_month = DateTime::Duration->new( days => 28 );
  my $start_month = $end->clone->subtract_duration( $duration_month );
  my $month_transaction_category_rs = $c->schema->resultset('ViewQuantisedTransactionCategory' . $driver)->search(
    {
      purchase_time => {
        -between => [
          $dtf->format_datetime($start_month),
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
        },
      ],
      group_by => [ qw/ category_id quantised_weeks essential / ],
    }
  );

  my $category_list = $c->schema->resultset('Category')->as_hash;

  for my $cat_trans ( $month_transaction_category_rs->all ) {
    my $quantised = $c->db_datetime_parser->parse_datetime($cat_trans->get_column('quantised'));
    my $days = $c->format_iso_date( $quantised ) || 0;
    my $category = $cat_trans->get_column('category_id') || 0;
    my $value = ($cat_trans->get_column('value') || 0) / 100000;
    $data->{cat_total}->{$category_list->{$category}} += $value;
    $data->{categories}->{$days}->{$category_list->{$category}} += $value;
    next unless $cat_trans->get_column('essential');
    $data->{essentials}->{$days}->{value} += $value;
  }

  for my $day ( keys %{ $data->{categories} } ) {
    my @days = ( map{ {
      days => $day,
      value => $data->{categories}->{$day}->{$_},
      category => $_,
    } } keys %{ $data->{categories}->{$day} } );
    $data->{categories}->{$day} = [ sort { $b->{value} <=> $a->{value} } @days ];
  }

  return $c->render( json => {
    success => Mojo::JSON->true,
    data => $data,
    weeks => $weeks,
    sectors => $sectors,
  });
}

sub post_leaderboards {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $leaderboard_rs = $c->schema->resultset('Leaderboard');

  $validation->required('type')->in_resultset( 'type', $leaderboard_rs );

  return $c->api_validation_error if $validation->has_error;

  my $today_board = $leaderboard_rs->get_latest( $validation->param('type') );

  my $today_values = $today_board->values->search(
    {},
    {
      order_by => { -asc => 'me.position' },
      columns => [
        qw/
          me.value
          me.trend
          me.position
        /,
        { display_name => 'customer.display_name' },
      ],
      join => { entity => 'customer' },
    },
  );
  $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

  my @leaderboard_array = $today_values->all;

  if ( $validation->param('type') =~ /total$/ ) {
    @leaderboard_array = (map {
      {
        %$_,
        value => $_->{value} / 100000,
      }
    } @leaderboard_array);
  }

  my $current_user_position = $today_values->find({ entity_id => $c->stash->{api_user}->entity->id });

  return $c->render( json => {
    success => Mojo::JSON->true,
    leaderboard => [ @leaderboard_array ],
    user_position => defined $current_user_position ? $current_user_position->{position} : 0,
  });
}

sub post_leaderboards_paged {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $leaderboard_rs = $c->schema->resultset('Leaderboard');

  $validation->required('type')->in_resultset( 'type', $leaderboard_rs );
  $validation->optional('page')->number;

  return $c->api_validation_error if $validation->has_error;

  my $page = 1;

  my $today_board = $leaderboard_rs->get_latest( $validation->param('type') );
  my @leaderboard_array;
  my $current_user_position;
  my $values_count = 0;
  if ( defined $today_board ) {

    if ( !defined $validation->param('page') || $validation->param('page') < 1 ) {
      my $user_position = $today_board->values->find({ entity_id => $c->stash->{api_user}->entity->id });
      $page = int(defined $user_position ? $user_position->{position} : 0 / 10) + 1;
    } else {
      $page = $validation->param('page');
    }

    my $today_values = $today_board->values->search(
      {},
      {
        page => $page,
        rows => 10,
        order_by => { -asc => 'me.position' },
        columns => [
          qw/
            me.value
            me.trend
            me.position
          /,
          { display_name => 'customer.display_name' },
        ],
        join => { entity => 'customer' },
      },
    );
    $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

    @leaderboard_array = $today_values->all;

    $values_count = $today_values->pager->total_entries;

    if ( $validation->param('type') =~ /total$/ ) {
      @leaderboard_array = (map {
        {
          %$_,
          value => $_->{value} / 100000,
        }
      } @leaderboard_array);
    }

    $current_user_position = $today_values->find({ entity_id => $c->stash->{api_user}->entity->id });
  }
  return $c->render( json => {
    success => Mojo::JSON->true,
    leaderboard => [ @leaderboard_array ],
    user_position => defined $current_user_position ? $current_user_position->{position} : 0,
    page => $page,
    count => $values_count,
  });
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
