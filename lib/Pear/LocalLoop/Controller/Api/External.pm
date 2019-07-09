package Pear::LocalLoop::Controller::Api::External;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

sub post_lcc_transactions {
  my $c = shift;

  use Devel::Dwarn;
  Dwarn "hello";

  my $user = $c->stash->{api_user};

  # TODO Check the user is lancaster city council

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->optional('page')->number;

  return $c->api_validation_error if $validation->has_error;

  my $lcc_import_ext_ref = $self->schema->resultset('ExternalReference')->find_or_create({ name => 'LCC CSV' });

  my $lcc_transactions = $lcc_import_ext_ref->search_related('transactions',
    undef,
    {
      page => $validation->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'purchase_time' },
    },
  );

  # purchase_time needs timezone attached to it
  my @transaction_list = (
    map {{
      transaction_external_id => $_->external_id,
      seller => $_->transaction->seller->name,
      net_value => $_->transaction->value,
      gross_value => $_->transaction->meta->gross_value,
      sales_tax_value => $_->transaction->meta->sales_tax_value,
      purchase_time => $c->transaction->format_iso_datetime($_->purchase_time),
    }} $transactions->all
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

  my $is_lcc = $self->entity->organisation->count({ name => "Lancashire County Council" });

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->optional('page')->number;

  return $c->api_validation_error if $validation->has_error;

  my $lcc_import_ext_ref = $self->schema->resultset('ExternalReference')->find_or_create({ name => 'LCC CSV' });

  my $lcc_suppliers = $lcc_import_ext_ref->search_related('organisations',
    undef,
    {
      page => $validation->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'organisation.name' },
    },
  );

  # purchase_time needs timezone attached to it
  my @supplier_list = (
    map {{
      supplier_external_id => $_->external_id,
      name => $_->organisation->name,
      street => $_->organisation->street_name,
      town => $_->organisation->town,
      postcode => $_->organisation->post_code,
      country => $_->organisation->country,
    }} $lcc_suppliers->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    suppliers => \@supplier_list,
    page_no => $lcc_suppliers->pager->total_entries,
  });
}

1;
