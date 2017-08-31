package Pear::LocalLoop::Controller::Api::V1::Organisation::Graphs;
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

  my $org = $c->stash->{api_user}->entity;

  my $data = { day => [], count => [] };

  my $start = DateTime->today;
  my $end = $start->clone->subtract_duration( $duration );

  my $dtf = $c->schema->storage->datetime_parser;

  while ( $end < $start ) {
    my $moving_end = $end->clone->add( days => 1 );
    my $transactions = $c->schema->resultset('Transaction')->search({
      seller_id => $org->id,
      purchase_time => { '-between' => [ $dtf->format_datetime($end), $dtf->format_datetime($moving_end) ] },
    })->count;
    push @{$data->{day}}, $end->day_name;
    push @{$data->{count}}, $transactions;
    $end->add( days => 1 );
  }

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      graph => $data,
    }
  );
}

1;
