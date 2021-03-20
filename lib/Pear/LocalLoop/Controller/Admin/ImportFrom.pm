package Pear::LocalLoop::Controller::Admin::ImportFrom;
use Mojo::Base 'Mojolicious::Controller';
use Moo;
use Try::Tiny;
use Mojo::File qw/path/;

sub index {
    my $c = shift;
    $c->stash->{org_entities} = [
        map { { id => $_->entity_id, name => $_->name } }
          $c->schema->resultset('Organisation')->search(
            { name    => { like => '%lancashire%' } },
            { columns => [qw/ entity_id name /] }
          )
    ];

    $c->app->max_request_size(104857600);
}

sub post_suppliers {
    my $c = shift;

    unless ( $c->param('suppliers_csv') ) {
        $c->flash( error => "No CSV file given" );
        return $c->redirect_to('/admin/import_from');
    }

    # Check file size
    if ( $c->req->is_limit_exceeded ) {
        $c->flash( error => "CSV file size is too large" );
        return $c->redirect_to('/admin/import_from');
    }

    my $file = $c->param('suppliers_csv');

    my $filename =
      path( $c->app->config->{upload_path}, time . 'suppliers.csv' );

    $file->move_to($filename);

    my $job_id = $c->minion->enqueue( 'csv_supplier_import' => [$filename] );

    my $job_url = $c->url_for("/admin/minion/jobs?id=$job_id")->to_abs;

    $c->flash( success =>
          "CSV import started, see status of minion job at: $job_url" );
    return $c->redirect_to('/admin/import_from');
}

sub post_postcodes {
    my $c = shift;

    unless ( $c->param('postcodes_csv') ) {
        $c->flash( error => "No CSV file given" );
        return $c->redirect_to('/admin/import_from');
    }

    # Check file size
    if ( $c->req->is_limit_exceeded ) {
        $c->flash( error => "CSV file size is too large" );
        return $c->redirect_to('/admin/import_from');
    }

    my $file = $c->param('postcodes_csv');

    my $filename =
      path( $c->app->config->{upload_path}, time . 'postcodes.csv' );

    $file->move_to($filename);

    my $job_id = $c->minion->enqueue( 'csv_postcode_import' => [$filename] );

    my $job_url = $c->url_for("/admin/minion/jobs?id=$job_id")->to_abs;

    $c->flash( success =>
          "CSV import started, see status of minion job at: $job_url" );
    return $c->redirect_to('/admin/import_from');
}

sub post_transactions {
    my $c = shift;

    unless ( $c->param('entity_id') ne '' ) {
        $c->flash( error => "Please Choose an organisation" );
        return $c->redirect_to('/admin/import_from');
    }

    unless ( $c->param('transactions_csv') ) {
        $c->flash( error => "No CSV file given" );
        return $c->redirect_to('/admin/import_from');
    }

    # Check file size
    if ( $c->req->is_limit_exceeded ) {
        $c->flash( error => "CSV file size is too large" );
        return $c->redirect_to('/admin/import_from');
    }

    my $file = $c->param('transactions_csv');

    my $filename =
      path( $c->app->config->{upload_path}, time . 'transactions.csv' );

    $file->move_to($filename);

    my $job_id = $c->minion->enqueue(
        'csv_transaction_import' => [ $filename, $c->param('entity_id') ] );

    my $job_url = $c->url_for("/admin/minion/jobs?id=$job_id")->to_abs;

    $c->flash( success =>
          "CSV import started, see status of minion job at: $job_url" );
    return $c->redirect_to('/admin/import_from');
}

sub org_search {
    my $c    = shift;
    my $term = $c->param('term');

    my $rs = $c->schema->resultset('Organisation')->search(
        { name => { like => $term . '%' } },
        {
            join    => 'entity',
            columns => [qw/ me.name entity.id /]
        },
    );

    my @results = (
        map { { label => $_->name, value => $_->entity->id, } } $rs->all
    );

    $c->render( json => \@results );
}

1;
