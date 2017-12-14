package Pear::LocalLoop::Controller::Api::Stats;
use Mojo::Base 'Mojolicious::Controller';

use List::Util qw/ first /;

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

  my $duration = DateTime::Duration->new( weeks => 7 );
  my $end = DateTime->today;
  my $start = $end->clone->subtract_duration( $duration );

  my $data = { purchases => [] };

  my $dtf = $c->schema->storage->datetime_parser;
  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $transaction_rs = $c->schema->resultset('ViewQuantisedTransaction' . $driver)->search(
    {
      purchase_time => {
        -between => [
          $dtf->format_datetime($start),
          $dtf->format_datetime($end),
        ],
      },
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

  for ( $transaction_rs->all ) {
    push @{ $data->{ purchases } }, ($_->get_column('count') || 0);
  }

  return $c->render( json => {
    success => Mojo::JSON->true,
    data => $data,
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
    page => $page,
    count => $today_values->pager->total_entries,
  });
}

1;
