package Pear::LocalLoop::Controller::Admin::Organisations;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

has result_set => sub {
  my $c = shift;
  return $c->schema->resultset('Organisation');
};

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
  $validation->optional('is_local');
  $validation->optional('is_fair');

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
        is_local     => $validation->param('is_local'),
        is_fair      => $validation->param('is_fair'),
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
  my $transactions = $valid_org->entity->purchases->search(
    undef, {
      page => $c->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'submitted_at' },
    },
  );
  my $associations = $valid_org->entity->associations;
  my $assoc = {
    lis => defined $associations ? $associations->lis : 0,
    esta => defined $associations ? $associations->esta : 0,
  };

  $c->stash(
    valid_org => $valid_org,
    transactions => $transactions,
    associations => $assoc,
  );
}

sub valid_edit {
  my $c = shift;

  my $validation = $c->validation;
  $validation->required('name');
  $validation->optional('street_name');
  $validation->required('town');
  $validation->optional('sector');
  $validation->required('postcode')->postcode;
  $validation->optional('pending');
  $validation->optional('is_local');
  $validation->optional('is_fair');
  $validation->optional('is_lis');
  $validation->optional('is_esta');

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
        is_local    => $validation->param('is_local'),
        is_fair     => $validation->param('is_fair'),
      });
      $valid_org->entity->update_or_create_related( 'associations', {
        lis         => $validation->param('is_lis'),
        esta        => $validation->param('is_esta')
      });
    } );
  } finally {
    if ( @_ ) {use Devel::Dwarn; Dwarn \@_;
      $c->flash( error => 'Something went wrong Updating the Organisation' );
    } else {
      $c->flash( success => 'Updated Organisation' );
    }
  };
  $c->redirect_to( '/admin/organisations/' . $c->param('id') );
}

sub merge_list {
  my $c = shift;

  my $org_id = $c->param('id');
  my $org_result = $c->result_set->find($org_id);

  if ( defined $org_result->entity->user ) {
    $c->flash( error => 'Cannot merge from user-owned organisation!' );
    $c->redirect_to( '/admin/organisations/' . $org_id );
    return;
  }

  my $org_rs = $c->result_set->search(
    {
      id => { '!=' => $org_id },
    },
    {
      page => $c->param('page') || 1,
      rows => 10,
      order_by => { '-asc' => 'name' },
    }
  );

  $c->stash(
    org_result => $org_result,
    org_rs => $org_rs,
  );
}

sub merge_detail {
  my $c = shift;

  my $org_id = $c->param('id');
  my $org_result = $c->result_set->find($org_id);

  if ( defined $org_result->entity->user ) {
    $c->flash( error => 'Cannot merge from user-owned organisation!' );
    $c->redirect_to( '/admin/organisations/' . $org_id );
    return;
  }

  my $target_id = $c->param('target_id');
  my $target_result = $c->result_set->find($target_id);

  unless ( defined $target_result ) {
    $c->flash( error => 'Unknown target organisation' );
    $c->redirect_to( '/admin/organisations/' . $org_id . '/merge' );
    return;
  }

  $c->stash(
    org_result => $org_result,
    target_result => $target_result,
  );
}

sub merge_confirm {
  my $c = shift;

  my $org_id = $c->param('id');
  my $org_result = $c->result_set->find($org_id);

  if ( defined $org_result->entity->user ) {
    $c->flash( error => 'Cannot merge from user-owned organisation!' );
    $c->redirect_to( '/admin/organisations/' . $org_id );
    return;
  }

  my $target_id = $c->param('target_id');
  my $target_result = $c->result_set->find($target_id);
  my $confirm = $c->param('confirm');

  if ( $confirm eq 'checked' && defined $org_result && defined $target_result ) {
    try {
      $c->schema->txn_do( sub {
        # Done as an update, not update_all, so its damn fast - we're only
        # editing an id which is guaranteed to be an integer here, and this
        # makes it only one update statement.
        $org_result->entity->sales->update(
          { seller_id => $target_result->entity->id }
        );
        my $count = $org_result->entity->sales->count;
        die "Failed to migrate all sales" if $count;
        $org_result->entity->delete;
        $c->schema->resultset('ImportLookup')->search({ entity_id => $org_result->entity->id })->delete;
        my $org_count = $c->result_set->search({id => $org_result->id })->count;
        my $entity_count = $c->schema->resultset('Entity')->search({id => $org_result->entity->id })->count;
        die "Failed to remove org" if $org_count;
        die "Failed to remove entity" if $entity_count;
      });
    } catch {
      $c->app->log->warn($_);
    };
    $c->flash( error => 'Engage' );
  } else {
    $c->flash( error => 'You must tick the confirmation box to proceed' );
  }
  $c->redirect_to( '/admin/organisations/' . $org_id . '/merge/' . $target_id );
}

1;
