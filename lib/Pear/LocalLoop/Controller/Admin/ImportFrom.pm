package Pear::LocalLoop::Controller::Admin::ImportFrom;
use Mojo::Base 'Mojolicious::Controller';
use Devel::Dwarn;

sub index {
  my $c = shift;

  $c->app->max_request_size(1048576);
}

sub post_suppliers {
  my $c = shift;

  Dwarn "yahoo!";
  return $c->redirect_to( '/admin/import_from' );
}

sub post_transactions {
  my $c = shift;

  Dwarn "yahoo!";
  $c->flash( success => "CSV imported!" );
  return $c->redirect_to( '/admin/import_from' );
}

1;
