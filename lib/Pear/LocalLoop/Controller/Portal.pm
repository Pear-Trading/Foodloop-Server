package Pear::LocalLoop::Controller::Portal;
use Mojo::Base 'Mojolicious::Controller';

sub under {
  my $c = shift;

  $c->stash( api_user => $c->current_user );
  return 1;
}

1;
