package Pear::LocalLoop::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

}

sub auth_logout {
  my $c = shift;

  $c->logout;
  $c->redirect_to('/');
}


1;
