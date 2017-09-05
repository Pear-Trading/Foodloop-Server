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

# purchase_time needs timezone attached to it
  my @transaction_list = (
    map {{
      seller => $_->seller->name,
      value => $_->value,
      purchase_time => $_->purchase_time,
    }} $transactions->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    transactions => \@transaction_list,
  });
}

1;
