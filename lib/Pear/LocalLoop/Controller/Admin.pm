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
}

1;
