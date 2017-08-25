package Pear::LocalLoop::Controller::Admin::Organisations;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;
use Data::Dumper;

sub list {
  my $c = shift;

  my $valid_orgs_rs = $c->schema->resultset('Organisation');
  my $pending_orgs_rs = $c->schema->resultset('PendingOrganisation');

  $c->stash(
    valid_orgs_rs => $valid_orgs_rs,
    pending_orgs_rs => $pending_orgs_rs,
  );
}

sub add_org {
  my $c = shift;
}

sub add_org_submit {
  my $c = shift;

  my $validation = $c->validation;

  $validation->required('name');
  $validation->optional('street_name');
  $validation->required('town');
  $validation->optional('sector');
  $validation->optional('postcode')->postcode;

  if ( $validation->has_error ) {
    $c->flash( error => 'The validation has failed' );
    $c->app->log->warn(Dumper $validation);
    return $c->redirect_to( '/admin/organisations/add/' );
  }

  my $organisation;

  try {
    $organisation = $c->schema->resultset('Organisation')->create({
      name         => $validation->param('name'),
      street_name  => $validation->param('street_name'),
      town         => $validation->param('town'),
      sector       => $validation->param('sector'),
      postcode     => $validation->param('postcode'),
    });
  } finally {
    if ( @_ ) {
      $c->flash( error => 'Something went wrong Adding the Organisation' );
      $c->app->log->warn(Dumper @_);
    } else {
      $c->flash( success => 'Added Organisation' );
    }
  };
  $c->redirect_to( '/admin/organisations/add/' );
}

sub valid_read {
  my $c = shift;
  my $valid_org = $c->schema->resultset('Organisation')->find( $c->param('id') );
  my $transactions = $valid_org->transactions->search(
    undef, {
      page => $c->param('page') || 1,
      rows => 10,
    },
  );
  $c->stash(
    valid_org => $valid_org,
    transactions => $transactions,
  );
}

sub valid_edit {
  my $c = shift;

  my $validation = $c->validation;
  $validation->required('name');
  $validation->required('street_name');
  $validation->required('town');
  $validation->optional('sector');
  $validation->required('postcode')->postcode;

  if ( $validation->has_error ) {
    $c->flash( error => 'The validation has failed' );
    $c->app->log->warn(Dumper $validation);
    return $c->redirect_to( '/admin/organisations/valid/' . $c->param('id') );
  }

  my $valid_org = $c->schema->resultset('Organisation')->find( $c->param('id') );

  try {
    $c->schema->storage->txn_do( sub {
      $valid_org->update({
        name        => $validation->param('name'),
        street_name => $validation->param('street_name'),
        town        => $validation->param('town'),
        sector      => $validation->param('sector'),
        postcode    => $validation->param('postcode'),
      });
    } );
  } finally {
    if ( @_ ) {
      $c->flash( error => 'Something went wrong Updating the Organisation' );
      $c->app->log->warn(Dumper @_);
    } else {
      $c->flash( success => 'Updated Organisation' );
    }
  };
  $c->redirect_to( '/admin/organisations/valid/' . $valid_org->id );
}

sub pending_read {
  my $c = shift;
  my $pending_org = $c->schema->resultset('PendingOrganisation')->find( $c->param('id') );
  my $transactions = $pending_org->transactions->search(
    undef, {
      page => $c->param('page') || 1,
      rows => 10,
    },
  );
  $c->stash(
    pending_org => $pending_org,
    transactions => $transactions,
  );
}

sub pending_edit {
  my $c = shift;

  my $validation = $c->validation;
  $validation->required('name');
  $validation->required('street_name');
  $validation->required('town');
  $validation->required('postcode')->postcode;

  if ( $validation->has_error ) {
    $c->flash( error => 'The validation has failed' );
    $c->app->log->warn(Dumper $validation);
    return $c->redirect_to( '/admin/organisations/pending/' . $c->param('id') );
  }

  my $pending_org = $c->schema->resultset('PendingOrganisation')->find( $c->param('id') );

  try {
    $c->schema->storage->txn_do( sub {
      $pending_org->update({
        name        => $validation->param('name'),
        street_name => $validation->param('street_name'),
        town        => $validation->param('town'),
        postcode    => $validation->param('postcode'),
      });
    } );
  } finally {
    if ( @_ ) {
      $c->flash( error => 'Something went wrong Updating the Organisation' );
      $c->app->log->warn(Dumper @_);
    } else {
      $c->flash( success => 'Updated Organisation' );
    }
  };
  $c->redirect_to( '/admin/organisations/pending/' . $pending_org->id );
}

sub pending_approve {
  my $c = shift;
  my $pending_org = $c->schema->resultset('PendingOrganisation')->find( $c->param('id') );

  my $valid_org;
  try {
    $c->schema->storage->txn_do( sub {
      $valid_org = $c->schema->resultset('Organisation')->create({
        name        => $pending_org->name,
        street_name => $pending_org->street_name,
        town        => $pending_org->town,
        postcode    => $pending_org->postcode,
      });
      $c->copy_transactions_and_delete( $pending_org, $valid_org );
    } );
  } finally {
    if ( @_ ) {
      $c->flash( error => 'Something went wrong Validating the Organisation' );
      $c->redirect_to( '/admin/organisations/pending/' . $pending_org->id );
    } else {
      $c->flash( success => 'Validated Organisation' );
      $c->redirect_to( '/admin/organisations/valid/' . $valid_org->id );
    }
  }
}

1;
