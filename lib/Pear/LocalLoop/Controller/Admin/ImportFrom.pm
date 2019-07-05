package Pear::LocalLoop::Controller::Admin::ImportFrom;
use Mojo::Base 'Mojolicious::Controller';
use Moo;
use Devel::Dwarn;

use Pear::LocalLoop::Import::LCCCsv::Suppliers;
use Pear::LocalLoop::Import::LCCCsv::Transactions;

sub index {
  my $c = shift;

  $c->app->max_request_size(104857600);
}

sub post_suppliers {
  my $c = shift;

  unless ($c->param('suppliers_csv')) {
    $c->flash( error => "No CSV file given" );
    return $c->redirect_to( '/admin/import_from' );
  }

  # Check file size
  if ($c->req->is_limit_exceeded) {
    $c->flash( error => "CSV file size is too large" );
    return $c->redirect_to( '/admin/import_from' );
  }
  my $csv_import = Pear::LocalLoop::Import::LCCCsv::Suppliers->new(
    csv_string => $c->param('suppliers_csv')->slurp,
    schema => $c->app->schema
  )->import_csv;

  $c->flash( success => "CSV imported" );
  return $c->redirect_to( '/admin/import_from' );
}

sub post_transactions {
  my $c = shift;

  unless ($c->param('transactions_csv')) {
    $c->flash( error => "No CSV file given" );
    return $c->redirect_to( '/admin/import_from' );
  }

  # Check file size
  if ($c->req->is_limit_exceeded) {
    $c->flash( error => "CSV file size is too large" );
    return $c->redirect_to( '/admin/import_from' );
  }
  my $csv_import = Pear::LocalLoop::Import::LCCCsv::Transactions->new(
    csv_string => $c->param('transactions_csv')->slurp,
    schema => $c->app->schema
  )->import_csv;

  if ($csv_import->csv_error) {
    $c->flash( error => $csv_import->csv_error );
    return $c->redirect_to( '/admin/import_from' );
  } else {
    $c->flash( success => "CSV imported" );
    return $c->redirect_to( '/admin/import_from' );
  }

}

1;
