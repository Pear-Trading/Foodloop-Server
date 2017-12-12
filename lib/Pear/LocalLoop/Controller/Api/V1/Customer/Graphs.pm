package Pear::LocalLoop::Controller::Api::V1::Customer::Graphs;
use Mojo::Base 'Mojolicious::Controller';

has error_messages => sub {
  return {
    graph => {
      required => { message => 'Must request graph type', status => 400 },
      in => { message => 'Unrecognised graph type', status => 400 },
    },
  };
};

sub index {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->required('graph')->in( qw/
    customers_last_7_days
    customers_last_30_days
    sales_last_7_days
    sales_last_30_days
    purchases_last_7_days
    purchases_last_30_days
    customers_range
  / );

  return $c->api_validation_error if $validation->has_error;

  my $graph_sub = "graph_" . $validation->param('graph');

  unless ( $c->can($graph_sub) ) {
    # Secondary catch in case a mistake has been made
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => $c->error_messages->{graph}->{in}->{message},
        error => 'in',
      },
      status => $c->error_messages->{graph}->{in}->{status},
    );
  }

  return $c->$graph_sub;
}

sub graph_customers_range {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->required('start')->is_iso_date;
  $validation->required('end')->is_iso_date;

  return $c->api_validation_error if $validation->has_error;

  my $entity = $c->stash->{api_user}->entity;

  my $data = { labels => [], data => [] };
  my $start = $c->parse_iso_date( $validation->param('start') );
  my $end = $c->parse_iso_date( $validation->param('end') );

  while ( $start <= $end ) {
    my $next_end = $start->clone->add( days => 1 );
    my $transactions = $entity->sales
      ->search_between( $start, $next_end )
      ->count;
    push @{ $data->{ labels } }, $c->format_iso_date( $start );
    push @{ $data->{ data } }, $transactions;
    $start->add( days => 1 );
  }

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      graph => $data,
    }
  );
}

sub graph_customers_last_7_days {
  my $c = shift;

  my $duration = DateTime::Duration->new( days => 7 );
  return $c->_customers_last_duration( $duration );
}

sub graph_customers_last_30_days {
  my $c = shift;

  my $duration = DateTime::Duration->new( days => 30 );
  return $c->_customers_last_duration( $duration );
}

sub _customers_last_duration {
  my ( $c, $duration ) = @_;

  my $entity = $c->stash->{api_user}->entity;

  my $data = { labels => [], data => [] };

  my ( $start, $end ) = $c->_get_start_end_duration( $duration );

  while ( $start < $end ) {
    my $next_end = $start->clone->add( days => 1 );
    my $transactions = $entity->sales
      ->search_between( $start, $next_end )
      ->count;
    push @{ $data->{ labels } }, $start->day_name;
    push @{ $data->{ data } }, $transactions;
    $start->add( days => 1 );
  }

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      graph => $data,
    }
  );
}

sub graph_sales_last_7_days { return shift->_sales_last_duration( 7 ) }
sub graph_sales_last_30_days { return shift->_sales_last_duration( 30 ) }

sub _sales_last_duration {
  my ( $c, $day_duration ) = @_;

  my $duration = DateTime::Duration->new( days => $day_duration );
  my $entity = $c->stash->{api_user}->entity;

  my $data = { labels => [], data => [] };

  my ( $start, $end ) = $c->_get_start_end_duration( $duration );

  while ( $start < $end ) {
    my $next_end = $start->clone->add( days => 1 );
    my $transactions = $entity->sales
      ->search_between( $start, $next_end )
      ->get_column('value')
      ->sum || 0 + 0;
    push @{ $data->{ labels } }, $start->day_name;
    push @{ $data->{ data } }, $transactions / 100000;
    $start->add( days => 1 );
  }

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      graph => $data,
    }
  );
}

sub graph_purchases_last_7_days { return shift->_purchases_last_duration( 7 ) }
sub graph_purchases_last_30_days { return shift->_purchases_last_duration( 30 ) }

sub _purchases_last_duration {
  my ( $c, $day_duration ) = @_;

  my $duration = DateTime::Duration->new( days => $day_duration );
  my $entity = $c->stash->{api_user}->entity;

  my $data = { labels => [], data => [] };

  my ( $start, $end ) = $c->_get_start_end_duration( $duration );

  while ( $start < $end ) {
    my $next_end = $start->clone->add( days => 1 );
    my $transactions = $entity->purchases
      ->search_between( $start, $next_end )
      ->get_column('value')
      ->sum || 0 + 0;
    push @{ $data->{ labels } }, $start->day_name;
    push @{ $data->{ data } }, $transactions / 100000;
    $start->add( days => 1 );
  }

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      graph => $data,
    }
  );
}

sub _get_start_end_duration {
  my ( $c, $duration ) = @_;
  my $end = DateTime->today;
  my $start = $end->clone->subtract_duration( $duration );
  return ( $start, $end );
}

1;
