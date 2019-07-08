package Pear::LocalLoop::Controller::Admin::ImportFrom;
use Mojo::Base 'Mojolicious::Controller';
use Moo;
use Try::Tiny;
use Mojo::File qw/ path /;

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

  my $file = $c->param('suppliers_csv');

  my $filename = path($c->app->config->{upload_path}, time.'suppliers.csv' );

  $file->move_to($filename);

  my $job_id = $c->minion->enqueue('csv_supplier_import' => [$filename] );

  my $job_url = $c->url_for("/admin/minionjobs?id=$job_id")->to_abs;

  $c->flash(success => "CSV import started, see status of minion job at: $job_url");
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

  my $file = $c->param('transactions_csv');

  my $filename = path($c->app->config->{upload_path}, time.'transactions.csv' );

  $file->move_to($filename);

  my $job_id = $c->minion->enqueue('csv_transaction_import' => [$filename] );

  my $job_url = $c->url_for("/admin/minionjobs?id=$job_id")->to_abs;

  $c->flash(success => "CSV import started, see status of minion job at: $job_url");
  return $c->redirect_to( '/admin/import_from' );
}

1;
