package Pear::LocalLoop::Controller::Api::V1::Customer::Pies;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;

  my $purchase_rs = $entity->purchases;
  my $local_org_local_purchase = $purchase_rs->search({
    "me.distance" => { '<', 20000 },
    'organisation.is_local' => 1,
  },
  {
    join => { 'seller' => 'organisation' },
  }
  );

  my $local_org_non_local_purchase = $purchase_rs->search({
    "me.distance" => { '>=', 20000 },
    'organisation.is_local' => 1,
  },
  {
    join => { 'seller' => 'organisation' },
  }
  );

  my $non_local_org_local_purchase = $purchase_rs->search({
    "me.distance" => { '<', 20000 },
    'organisation.is_local' => 0,
  },
  {
    join => { 'seller' => 'organisation' },
  }
  );

  my $non_local_org_non_local_purchase = $purchase_rs->search({
    "me.distance" => { '>=', 20000 },
    'organisation.is_local' => 0,
  },
  {
    join => { 'seller' => 'organisation' },
  }
  );

  my $data = {
    'Local shop local purchaser' => $local_org_local_purchase->count,
    'Local shop non-local purchaser' => $local_org_non_local_purchase->count,
    'Non-local shop local purchaser' => $non_local_org_local_purchase->count,
    'Non-local shop non-local purchaser' => $non_local_org_non_local_purchase->count,
  };

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      pie => $data,
    }
  );

}

1;
