package Pear::LocalLoop::Controller::Admin::Organisations;
use Mojo::Base 'Mojolicious::Controller';

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
  $c->stash( valid_org => $valid_org );
}

sub pending_read {
  my $c = shift;
  my $pending_org = $c->schema->resultset('PendingOrganisation')->find( $c->param('id') );
  $c->stash( pending_org => $pending_org );
}

sub pending_approve {
  my $c = shift;
  my $pending_org = $c->schema->resultset('PendingOrganisation')->find( $c->param('id') );
  my $valid_org = $c->schema->resultset('Organisation')->create({
    name        => $pending_org->name,
    street_name => $pending_org->street_name,
    town        => $pending_org->town,
    postcode    => $pending_org->postcode,
  });
  $c->copy_transactions_and_delete( $pending_org, $valid_org );
  $c->flash( success => 'Validated Organisation' );
  $c->redirect_to( '/admin/organisations/valid/' . $valid_org->id );
}

1;
