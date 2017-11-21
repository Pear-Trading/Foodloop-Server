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
  my $feedback_rs = $c->schema->resultset('Feedback');
  my $pending_feedback_rs = $feedback_rs->search({ actioned => 0 });
  $c->stash(
    user_count => $user_rs->count,
    tokens => {
      total => $token_rs->count,
      unused => $token_rs->search({ used => 0 })->count,
    },
    pending_orgs => $pending_orgs_rs->count,
    pending_trans => $pending_transaction_rs->count,
    feedback => {
      total => $feedback_rs->count,
      pending => $pending_feedback_rs->count,
    },
  );
}

sub auth_login {
  my $c = shift;

  $c->app->log->debug( __PACKAGE__ . " admin login attempt for [" . $c->param('email') . "]" );

  if ( $c->authenticate($c->param('email'), $c->param('password')) ) {
    $c->redirect_to('/admin/home');
  } else {
    $c->app->log->info( __PACKAGE__ . " failed admin login for [" . $c->param('email') . "]" );
    $c->redirect_to('/admin');
  }
}

sub auth_logout {
  my $c = shift;

  $c->logout;
  $c->redirect_to('/admin');
}

1;
