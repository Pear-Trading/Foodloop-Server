package Pear::LocalLoop::Controller::Api::Transactions;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has error_messages => sub {
  return {
    email => {
      required => { message => 'No email sent.', status => 400 },
      email => { message => 'Email is invalid.', status => 400 },
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
      last_updated => $c->format_iso_datetime($_->last_updated),
      essential => $_->essential,
      category => ( defined $_->category ? $_->category->name : 'Uncategorised' ),
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
  #TODO check that user matches seller on database before updating for that id

}

1;
