package Pear::LocalLoop::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;
}

sub under {
  my $c = shift;

  if ( $c->is_user_authenticated ) {
    return 1 if defined $c->current_user->administrator;
  }
  $c->redirect_to('/');
  return undef;
}

sub login {
  my $c = shift;

  if ( $c->authenticate($c->param('email'), $c->param('password')) ) {
    $c->redirect_to('/admin/home');
  } else {
    $c->redirect_to('/admin');
  }
}

sub home {
  my $c = shift;
}

1;
