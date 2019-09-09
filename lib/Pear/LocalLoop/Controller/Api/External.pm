package Pear::LocalLoop::Controller::Api::External;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

sub post_lcc_transactions {
  my $c = shift;

  my $user = $c->stash->{api_user};

  # TODO Check the user is lancaster city council

  my $validation = $c->validation;
  $validation->input($c->stash->{api_json});
  $validation->optional('page')->number;
  $validation->optional('per_page')->number;
  $validation->optional('search');

  return $c->api_validation_error if $validation->has_error;

  my $search_ref = { 'me.buyer_id' => $user->entity->id };
  if ($validation->param('search')) {
    $search_ref->{"organisation.name"} = { '-like' => join('', '%', $validation->param('search'), '%') };
  }

  my $lcc_transactions = $c->schema->resultset('Transaction')->search(
    $search_ref,
    {
      page     => $validation->param('page') || 1,
      rows     => $validation->param('per_page') || 10,
      join     => [ 'transaction', 'organisation' ],
      order_by => { -desc => 'transaction.purchase_time' },
    });

  # purchase_time needs timezone attached to it
  my @transaction_list = (
    map {{
      transaction_external_id => $_->external_id,
      seller                  => $_->transaction->seller->name,
      net_value               => $_->transaction->meta->net_value,
      gross_value             => $_->transaction->meta->gross_value,
      sales_tax_value         => $_->transaction->meta->sales_tax_value,
      purchase_time           => $c->format_iso_datetime($_->transaction->purchase_time),
    }} $lcc_transactions->all
  );

  return $c->render(json => {
    success      => Mojo::JSON->true,
    transactions => \@transaction_list,
    page_no      => $lcc_transactions->pager->total_entries,
  });
}

sub post_lcc_suppliers {
  my $c = shift;

  my $user = $c->stash->{api_user};

  # TODO give an error if user is not of Lancashire County Council

  # my $is_lcc = $user->entity->organisation->count({ name => "Lancashire County Council" });

  my $v = $c->validation;
  $v->input($c->stash->{api_json});
  $v->optional('page')->number;
  $v->optional('sort_by');
  $v->optional('sort_dir');

  my $order_by = [
    { -asc => 'organisation.name' },
  ];
  if ($v->param('sort_by')) {
    my %dirs = ('asc' => '-asc', 'desc' => '-desc');
    my $dir = $dirs{$v->param('sort_dir')} // '-asc';
    my %sorts = (
      'name'     => 'organisation.name',
      'postcode' => 'organisation.postcode',
      'spend'    => 'total_spend',
    );
    my $sort = $sorts{$v->param('sort_by')} || 'organisation.name';
    $order_by->[0] = { $dir => $sort };
  }

  return $c->api_validation_error if $v->has_error;

  my $lcc_suppliers = $c->schema->resultset('Entity')->search(
    {
      'sales.buyer_id' => $user->entity->id,
    },
    {
      join      => [ 'sales', 'organisation' ],
      group_by  => [ 'me.id', 'organisation.id' ],
      '+select' => [
        {
          'sum' => 'sales.value',
          '-as' => 'total_spend',
        }
      ],
      '+as'     => [ 'total_spend' ],
      page      => $v->param('page') || 1,
      rows      => 10,
      order_by  => $order_by,
    }
  );

  my @supplier_list = (
    map {{
      entity_id => $_->id,
      name      => $_->name,
      street    => $_->organisation->street_name,
      town      => $_->organisation->town,
      postcode  => $_->organisation->postcode,
      country   => $_->organisation->country,
      spend     => ($_->get_column('total_spend') / 100000) // 0,
    }} $lcc_suppliers->all
  );

  return $c->render(json => {
    success   => Mojo::JSON->true,
    suppliers => \@supplier_list,
    page_no   => $lcc_suppliers->pager->total_entries,
  });
}

sub post_year_spend {
  my $c = shift;

  my $user = $c->stash->{api_user};

  # Temporary date lock for dev data
  my $last = DateTime->new(
    year  => 2019,
    month => 4,
    day   => 1
  );
  my $first = $last->clone->subtract(years => 1);

  my $dtf = $c->schema->storage->datetime_parser;
  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $spend_rs = $c->schema->resultset('ViewQuantisedTransaction' . $driver)->search(
    {
      purchase_time => {
        -between => [
          $dtf->format_datetime($first),
          $dtf->format_datetime($last),
        ],
      },
      buyer_id      => $user->entity->id,
    },
    {
      columns  => [
        {
          quantised   => 'quantised_days',
          count       => \"COUNT(*)",
          total_spend => { sum => 'value' },
        }
      ],
      group_by => 'quantised_days',
      order_by => { '-asc' => 'quantised_days' },
    }
  );

  my @graph_data = (
    map {{
      count => $_->get_column('count'),
      value => ($_->get_column('total_spend') / 100000) // 0,
      date  => $_->get_column('quantised'),
    }} $spend_rs->all,
  );

  return $c->render(json => {
    success => Mojo::JSON->true,
    data    => \@graph_data,
  });
}

sub post_supplier_count {
  my $c = shift;

  my $user = $c->stash->{api_user};

  # Temporary date lock for dev data
  my $last = DateTime->new(
    year  => 2019,
    month => 4,
    day   => 1
  );
  my $first = $last->clone->subtract(years => 1);

  my $dtf = $c->schema->storage->datetime_parser;
  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $spend_rs = $c->schema->resultset('ViewQuantisedTransaction' . $driver)->search(
    {
      purchase_time => {
        -between => [
          $dtf->format_datetime($first),
          $dtf->format_datetime($last),
        ],
      },
      buyer_id      => $user->entity->id,
    },
    {
      join => { 'seller' => 'organisation' },
      select => [
        { count => 'me.id', '-as' => 'count' },
        { sum => 'me.value', '-as' => 'total_spend' },
        'organisation.name',
        'me.quantised_days',
      ],
      as => [ qw/ count total_spend name quantised_days / ],
      group_by => [ qw/ me.quantised_days seller.id organisation.id / ],
      order_by => { '-asc' => 'me.quantised_days' },
    }
  );

  my @graph_data = (
    map {{
      count  => $_->get_column('count'),
      value  => ($_->get_column('total_spend') / 100000) // 0,
      date   => $_->get_column('quantised_days'),
      seller => $_->get_column('name'),
    }} $spend_rs->all,
  );

  return $c->render(json => {
    success => Mojo::JSON->true,
    data    => \@graph_data,
  });
}

sub post_supplier_history {
  my $c = shift;

  my $user = $c->stash->{api_user};

  # Temporary date lock for dev data
  my $last = DateTime->new(
    year  => 2019,
    month => 4,
    day   => 1
  );
  my $first = $last->clone->subtract(years => 1);
  my $second = $last->clone->subtract(months => 6);
  my $third = $last->clone->subtract(months => 3);

  my $dtf = $c->schema->storage->datetime_parser;
  my $year_rs = $c->schema->resultset('Entity')->search(
    {
      'sales.purchase_time' => {
        -between => [
          $dtf->format_datetime($first),
          $dtf->format_datetime($last),
        ],
      },
      'sales.buyer_id'      => $user->entity->id,
    },
    {
      join     => [ 'sales', 'organisation' ],
      columns  => [
        {
          id          => 'me.id',
          name        => 'organisation.name',
          count       => \"COUNT(*)",
          total_spend => { sum => 'sales.value' },
        }
      ],
      group_by => [ 'me.id', 'organisation.id' ],
      order_by => { '-asc' => 'organisation.name' },
    }
  );
  my $half_year_rs = $c->schema->resultset('Entity')->search(
    {
      'sales.purchase_time' => {
        -between => [
          $dtf->format_datetime($second),
          $dtf->format_datetime($last),
        ],
      },
      'sales.buyer_id'      => $user->entity->id,
    },
    {
      join     => [ 'sales', 'organisation' ],
      columns  => [
        {
          id          => 'me.id',
          name        => 'organisation.name',
          count       => \"COUNT(*)",
          total_spend => { sum => 'sales.value' },
        }
      ],
      group_by => [ 'me.id', 'organisation.id' ],
      order_by => { '-asc' => 'organisation.name' },
    }
  );
  my $quarter_year_rs = $c->schema->resultset('Entity')->search(
    {
      'sales.purchase_time' => {
        -between => [
          $dtf->format_datetime($third),
          $dtf->format_datetime($last),
        ],
      },
      'sales.buyer_id'      => $user->entity->id,
    },
    {
      join     => [ 'sales', 'organisation' ],
      columns  => [
        {
          id          => 'me.id',
          name        => 'organisation.name',
          count       => \"COUNT(*)",
          total_spend => { sum => 'sales.value' },
        }
      ],
      group_by => [ 'me.id', 'organisation.id' ],
      order_by => { '-asc' => 'organisation.name' },
    }
  );

  my %data;
  for my $row ($year_rs->all) {
    $data{$row->get_column('id')} = {
      id            => $row->get_column('id'),
      name          => $row->get_column('name'),
      quarter_count => 0,
      quarter_total => 0,
      half_count    => 0,
      half_total    => 0,
      year_count    => $row->get_column('count'),
      year_total    => $row->get_column('total_spend') / 100000,
    };
  }

  for my $row ($half_year_rs->all) {
    $data{$row->get_column('id')} = {
      id            => $row->get_column('id'),
      name          => $row->get_column('name'),
      quarter_count => 0,
      quarter_total => 0,
      half_count    => $row->get_column('count'),
      half_total    => $row->get_column('total_spend') / 100000,
      year_count    => 0,
      year_total    => 0,
      %{$data{$row->get_column('id')}},
    };
  }

  for my $row ($quarter_year_rs->all) {
    $data{$row->get_column('id')} = {
      id            => $row->get_column('id'),
      name          => $row->get_column('name'),
      quarter_count => $row->get_column('count'),
      quarter_total => $row->get_column('total_spend') / 100000,
      half_count    => 0,
      half_total    => 0,
      year_count    => 0,
      year_total    => 0,
      %{$data{$row->get_column('id')}},
    };
  }

  return $c->render(json => {
    success => Mojo::JSON->true,
    data    => [ values %data ],
  });
}

sub post_lcc_table_summary {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input($c->stash->{api_json});

  my $transaction_rs = $c->schema->resultset('Transaction');

  my $ward_transactions_rs = $transaction_rs->search({},
    {
      join => { seller => { postcode => { gb_postcode => 'ward' } } },
      group_by => 'ward.id',
      select => [
        { count => 'me.id', '-as' => 'count' },
        { sum => 'me.value', '-as' => 'sum' },
        'ward.ward'
      ],
      as => [ qw/ count sum ward_name /],
    }
  );

  my $transaction_type_data = {};

  for my $meta ( qw/
    local_service
    regional_service
    national_service
    private_household_rebate
    business_tax_and_rebate
    stat_loc_gov
    central_loc_gov
  / ) {
    my $transaction_type_rs = $transaction_rs->search(
      {
        'meta.'.$meta => 1,
      },
      {
        join => 'meta',
        group_by => 'meta.' . $meta,
        select => [
          { count => 'me.id', '-as' => 'count' },
          { sum => 'me.value', '-as' => 'sum' },
        ],
        as => [ qw/ count sum /],
      }
    )->first;


    $transaction_type_data->{$meta} = {
      ( $transaction_type_rs ? (
        count => $transaction_type_rs->get_column('count'),
        sum => $transaction_type_rs->get_column('sum'),
        ) : () ),
    }
  }

  my @ward_transaction_list = (
    map {{
      ward => $_->get_column('ward_name') || "N/A",
      sum => $_->get_column('sum') / 100000,
      count => $_->get_column('count'),
    }} $ward_transactions_rs->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    wards => \@ward_transaction_list,
    types => $transaction_type_data,
  });
}

1;
