package Pear::LocalLoop::Controller::Admin::Organisations;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

sub list {
  my $c = shift;

  my $valid_orgs_rs = $c->schema->resultset('Organisation');
  my $pending_orgs_rs = $c->schema->resultset('PendingOrganisation');

  $c->stash(
    valid_orgs_rs => $valid_orgs_rs,
    pending_orgs_rs => $pending_orgs_rs,
  );
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
