package Pear::LocalLoop::Controller::Admin::Organisations;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

sub list {
  my $c = shift;

  my $orgs_rs = $c->schema->resultset('Organisation')->search(
    undef,
    {
      page => $c->param('page') || 1,
      rows => 10,
      order_by => { -asc => 'name' },
    },
  );

  $c->stash(
    orgs_rs => $orgs_rs,
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
  $validation->optional('pending');

  if ( $validation->has_error ) {
    $c->flash( error => 'The validation has failed' );
    return $c->redirect_to( '/admin/organisations/add' );
  }

  my $organisation;

  try {
    my $entity = $c->schema->resultset('Entity')->create({
      organisation => {
        name         => $validation->param('name'),
        street_name  => $validation->param('street_name'),
        town         => $validation->param('town'),
        sector       => $validation->param('sector'),
        postcode     => $validation->param('postcode'),
        submitted_by_id => $c->current_user->id,
        pending     => defined $validation->param('pending') ? 0 : 1,
      },
      type => 'organisation',
    });
    $organisation = $entity->organisation;
  } finally {
    if ( @_ ) {
      $c->flash( error => 'Something went wrong Adding the Organisation' );
      $c->redirect_to( '/admin/organisations/add' );
    } else {
      $c->flash( success => 'Added Organisation' );
      $c->redirect_to( '/admin/organisations/' . $organisation->id);
    }
  };
}

sub valid_read {
  my $c = shift;
  my $valid_org = $c->schema->resultset('Organisation')->find( $c->param('id') );
  my $transactions = $valid_org->entity->sales->search(
    undef, {
      page => $c->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'submitted_at' },
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
  $validation->optional('pending');

  if ( $validation->has_error ) {
    $c->flash( error => 'The validation has failed' );
    return $c->redirect_to( '/admin/organisations/' . $c->param('id') );
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
        pending     => defined $validation->param('pending') ? 0 : 1,
      });
    } );
  } finally {
    if ( @_ ) {
      $c->flash( error => 'Something went wrong Updating the Organisation' );
    } else {
      $c->flash( success => 'Updated Organisation' );
    }
  };
  $c->redirect_to( '/admin/organisations/');
}

1;
