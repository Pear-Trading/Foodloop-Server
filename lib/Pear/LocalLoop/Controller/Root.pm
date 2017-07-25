package Pear::LocalLoop::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

#  if ( $c->is_user_authenticated ) {
#   $c->redirect_to('/home');
#  }
}

sub under {
  my $c = shift;

  if ( $c->is_user_authenticated ) {
    return 1;
  }
  $c->redirect_to('/');
  return undef;
}

sub auth_login {
  my $c = shift;

  if ( $c->authenticate($c->param('email'), $c->param('password')) ) {
    $c->redirect_to('/home');
  } else {
    $c->redirect_to('/');
  }
}

sub auth_logout {
  my $c = shift;

  $c->logout;
  $c->redirect_to('/');
}

sub home {
  my $c = shift;
}

1;
