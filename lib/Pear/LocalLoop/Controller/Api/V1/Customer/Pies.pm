package Pear::LocalLoop::Controller::Api::V1::Customer::Pies;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;
  my $data = { data => [] };

  my $data = {
    'Local shop local purchaser' => 20,
    'Local shop non-local purchaser' => 20,
    'Non-local shop local purchaser' => 20,
    'Non-local shop non-local purchaser' => 20,
  };

  #TODO insert code fetching numbers here

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      pie => $data,
    }
  );

}

1;
