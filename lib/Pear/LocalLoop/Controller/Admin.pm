package Pear::LocalLoop::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

sub under {
  my $c = shift;

  if ( $c->is_user_authenticated ) {
    return 1 if defined $c->current_user->administrator;
    $c->redirect_to('/home');
  } else {
    $c->redirect_to('/');
  }
  return undef;
}

sub home {
  my $c = shift;

  my $user_rs = $c->schema->resultset('User');
  my $token_rs = $c->schema->resultset('AccountToken');
  my $pending_orgs_rs = $c->schema->resultset('PendingOrganisation');
  my $pending_transaction_rs = $c->schema->resultset('PendingTransaction');
  $c->stash(
    user_count => $user_rs->count,
    tokens => {
      total => $token_rs->count,
      unused => $token_rs->search({ used => 0 })->count,
    },
    pending_orgs => $pending_orgs_rs->count,
    pending_trans => $pending_transaction_rs->count,
  );
}

1;
