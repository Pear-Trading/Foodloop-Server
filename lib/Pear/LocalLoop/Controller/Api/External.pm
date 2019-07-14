package Pear::LocalLoop::Controller::Api::External;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

sub post_lcc_transactions {
  my $c = shift;

  my $user = $c->stash->{api_user};

  # TODO Check the user is lancaster city council

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->optional('page')->number;

  return $c->api_validation_error if $validation->has_error;

  my $lcc_import_ext_ref = $c->schema->resultset('ExternalReference')->find({ name => 'LCC CSV' });

  return 0 unless $lcc_import_ext_ref;

  my $lcc_transactions = $lcc_import_ext_ref->transactions->search(
  undef,
  {
    page => $validation->param('page') || 1,
    rows => 10,
    join => 'transaction',
    order_by => { -desc => 'transaction.purchase_time' },
  });

  # purchase_time needs timezone attached to it
  my @transaction_list = (
    map {{
      transaction_external_id => $_->external_id,
      seller => $_->transaction->seller->name,
      net_value => $_->transaction->meta->net_value,
      gross_value => $_->transaction->meta->gross_value,
      sales_tax_value => $_->transaction->meta->sales_tax_value,
      purchase_time => $c->format_iso_datetime($_->transaction->purchase_time),
    }} $lcc_transactions->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    transactions => \@transaction_list,
    page_no => $lcc_transactions->pager->total_entries,
  });
}

sub post_lcc_suppliers {
  my $c = shift;

  my $user = $c->stash->{api_user};

  # TODO give an error if user is not of Lancashire County Council

  # my $is_lcc = $user->entity->organisation->count({ name => "Lancashire County Council" });

  my $v = $c->validation;
  $v->input( $c->stash->{api_json} );
  $v->optional('page')->number;
  $v->optional('sort_by');
  $v->optional('sort_dir');

  my $order_by = [
    { -asc => 'organisation.name' },
    { -asc => 'seller.id' },
  ];
  if ( $v->param('sort_by') ) {
    my %dirs = ( 'asc' => '-asc', 'desc' => '-desc' );
    my $dir = $dirs{$v->param('sort_dir')} // '-asc';
    my %sorts = (
      'name' => 'organisation.name',
      'postcode' => 'organisation.postcode',
      'spend' => 'total_spend',
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
      join => ['sales', 'organisation'],
      group_by  => ['me.id', 'organisation.id'],
      '+select' => [
        {
          'sum' => 'sales.value',
          '-as' => 'total_spend',
        }
      ],
      '+as' => ['total_spend'],
      page => $v->param('page') || 1,
      rows => 10,
      order_by => $order_by,
    }
  );

  my @supplier_list = (
    map {{
      entity_id => $_->id,
      name => $_->name,
      street => $_->organisation->street_name,
      town => $_->organisation->town,
      postcode => $_->organisation->postcode,
      country => $_->organisation->country,
      spend => ($_->get_column('total_spend') / 100000) // 0,
    }} $lcc_suppliers->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    suppliers => \@supplier_list,
    page_no => $lcc_suppliers->pager->total_entries,
  });
}

1;
