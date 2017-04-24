package Pear::LocalLoop::Controller::Api::Info;
use Mojo::Base 'Mojolicious::Controller';

sub get_ages {
  my $c = shift;

  my $ages = $c->schema->resultset('AgeRange');

  $c->render( json => { ages => [ $ages->all ] } );
}

1;
