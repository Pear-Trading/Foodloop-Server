package Pear::LocalLoop::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

sub under {
  my $c = shift;

  if ( $c->is_user_authenticated ) {
    return 1 if $c->current_user->is_admin;
  }
  $c->redirect_to('/admin');
  return 0;
}

sub home {
  my $c = shift;

  my $user_rs = $c->schema->resultset('User');
  my $token_rs = $c->schema->resultset('AccountToken');
  my $pending_orgs_rs = $c->schema->resultset('Organisation')->search({ pending => 1 });
  my $pending_transaction_rs = $pending_orgs_rs->entity->sales;
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

sub auth_login {
  my $c = shift;

  if ( $c->authenticate($c->param('email'), $c->param('password')) ) {
    $c->redirect_to('/admin/home');
  } else {
    $c->redirect_to('/admin');
  }
}

sub auth_logout {
  my $c = shift;

  $c->logout;
  $c->redirect_to('/admin');
}

1;
