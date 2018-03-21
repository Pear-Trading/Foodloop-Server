package Pear::LocalLoop::Controller::Api::Transactions;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has error_messages => sub {
  return {
    email => {
      required => { message => 'No email sent.', status => 400 },
      email => { message => 'Email is invalid.', status => 400 },
    },
    value => {
      required => { message => 'transaction amount is missing', status => 400 },
      number => { message => 'transaction amount does not look like a number', status => 400 },
      gt_num => { message => 'transaction amount cannot be equal to or less than zero', status => 400 },
    },
    apply_time => {
      required => { message => 'purchase time is missing', status => 400 },
      is_full_iso_datetime => { message => 'time is in incorrect format', status => 400 },
    },
    id => {
      required => { message => 'Recurring Transaction not found', status => 400 },
    },
    category => {
      in_resultset => { message => 'Category is invalid', status => 400 },
    },
  };
};

sub post_transaction_list_purchases {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->optional('page')->number;

  return $c->api_validation_error if $validation->has_error;

  my $transactions = $user->entity->purchases->search(
    undef, {
      page => $validation->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'purchase_time' },
    },
  );

  my $recurring_transactions = $c->schema->resultset('TransactionRecurring')->search({
    buyer_id => $user->id,
  });

  # purchase_time needs timezone attached to it
  my @transaction_list = (
    map {{
      seller => $_->seller->name,
      value => $_->value / 100000,
      purchase_time => $c->format_iso_datetime($_->purchase_time),
    }} $transactions->all
  );

  my @recurring_transaction_list = (
    map {{
      id => $_->id,
      seller => $_->seller->name,
      value => $_->value / 100000,
      start_time => $c->format_iso_datetime($_->start_time),
      last_updated => $c->format_iso_datetime($_->last_updated) || undef,
      essential => $_->essential,
      category => $_->category_id || 0,
      recurring_period => $_->recurring_period,
    }} $recurring_transactions->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    transactions => \@transaction_list,
    recurring_transactions => \@recurring_transaction_list,
    page_no => $transactions->pager->total_entries,
  });
}

sub update_recurring {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->required('id');

  return $c->api_validation_error if $validation->has_error;

  my $id = $validation->param('id');

  my $recur_transaction = $c->schema->resultset('TransactionRecurring')->find($id);
  unless ( $recur_transaction ) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => 'Error Finding Recurring Transaction',
        error   => 'recurring_error',
      },
      status => 400,
    );
  }

  $validation->required('recurring_period');
  $validation->required('apply_time')->is_full_iso_datetime;
  $validation->optional('category')->in_resultset( 'id', $c->schema->resultset('Category'));
  $validation->optional('essential');
  $validation->required('value');

  return $c->api_validation_error if $validation->has_error;

  my $apply_time = $c->parse_iso_datetime($validation->param('apply_time'));

  $c->schema->storage->txn_do( sub {
    $recur_transaction->update({
      start_time       => $c->format_db_datetime($apply_time),
      last_updated     => undef,
      category_id      => $validation->param('category'),
      essential        => $validation->param('essential'),
      value            => $validation->param('value') * 100000,
      recurring_period => $validation->param('recurring_period'),
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Recurring Transaction Updated Successfully',
  });

}

sub delete_recurring {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->required('id');

  return $c->api_validation_error if $validation->has_error;

  my $id = $validation->param('id');

  my $recur_transaction = $c->schema->resultset('TransactionRecurring')->find($id);
  unless ( $recur_transaction ) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => 'Error Finding Recurring Transaction',
        error   => 'recurring_error',
      },
      status => 400,
    );
  }

  $recur_transaction->delete;

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Recurring Transaction Deleted Successfully',
  });

}

1;
