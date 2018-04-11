package Pear::LocalLoop::Controller::Api::V1::Customer::Pies;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;

  my $data = { local_all => {}, cat_total => {}, categories => {}, essentials => {} };

  my $purchase_rs = $entity->purchases;

  my $purchase_no_essential_rs = $purchase_rs->search({
    "me.essential" => 1,
  });

  $data->{essentials} = {
    purchase_no_total => $purchase_rs->count,
    purchase_no_essential_total => $purchase_no_essential_rs->count,
  };

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

  $data->{local_all} = {
    'Local shop local purchaser' => $local_org_local_purchase->count,
    'Local shop non-local purchaser' => $local_org_non_local_purchase->count,
    'Non-local shop local purchaser' => $non_local_org_local_purchase->count,
    'Non-local shop non-local purchaser' => $non_local_org_non_local_purchase->count,
  };

  my $duration = DateTime::Duration->new( days => 28 );
  my $end = DateTime->today;
  my $start = $end->clone->subtract_duration( $duration );

  my $dtf = $c->schema->storage->datetime_parser;
  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $month_transaction_category_rs = $c->schema->resultset('ViewQuantisedTransactionCategory' . $driver)->search(
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

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      data => $data,
    }
  );

}

1;
