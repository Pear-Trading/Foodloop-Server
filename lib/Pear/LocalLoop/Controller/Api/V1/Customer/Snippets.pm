package Pear::LocalLoop::Controller::Api::V1::Customer::Snippets;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;
  my $data = {
    user_sum => 0,
    user_position => 0,
  };

  my $user_rs = $entity->purchases;
  $data->{ user_sum } = $user_rs->get_column('value')->sum || 0;
  $data->{ user_sum } /= 100000;

  my $leaderboard_rs = $c->schema->resultset('Leaderboard');
  my $monthly_board = $leaderboard_rs->get_latest( 'monthly_total' );
  my $monthly_values = $monthly_board->values;
  $data->{ user_position } = $monthly_values ? $monthly_values->find({ entity_id => $entity->id })->position : 0;

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      snippets => $data,
    }
  );

}

1;
