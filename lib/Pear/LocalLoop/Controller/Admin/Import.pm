package Pear::LocalLoop::Controller::Admin::Import;
use Mojo::Base 'Mojolicious::Controller';

use Text::CSV;
use Try::Tiny;

has result_set => sub {
  my $c = shift;
  return $c->schema->resultset('ImportSet');
};

sub index {
  my $c = shift;

  my $import_rs = $c->result_set->search(
    undef,
    {
      page => $c->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'date' },
    },
  );
  $c->stash( import_rs => $import_rs );
}

sub list {
  my $c = shift;
  my $set_id = $c->param('set_id');

  my $include_ignored = $c->param('ignored');
  my $include_imported = $c->param('imported');

  my $import_set      = $c->result_set->find($set_id);
  my $import_value_rs = $c->result_set->get_values($set_id, $include_ignored, $include_imported);
  my $import_users_rs = $c->result_set->get_users($set_id, $include_ignored, $include_imported);
  my $import_org_rs   = $c->result_set->get_orgs($set_id, $include_ignored, $include_imported);
  my $import_lookup_rs = $c->result_set->get_lookups($set_id);

  $c->stash(
    import_set => $import_set,
    import_value_rs => $import_value_rs,
    import_users_rs => $import_users_rs,
    import_org_rs => $import_org_rs,
    import_lookup_rs => $import_lookup_rs,
  );
}

sub get_add {
  my $c = shift;
}

sub post_add {
  my $c = shift;
  
  my $csv_data = $c->param('csv');
  my $date_format = $c->param('date_format');

  my $csv = Text::CSV->new({
    binary => 1,
    allow_whitespace => 1,
  });

  open my $fh, '<', \$csv_data;

  # List context returns the actual headers
  my @csv_headers;
  my $error;
  try {
    @csv_headers = $csv->header( $fh );
  } catch {
    $error = $_;
  };

  if ( defined $error ) {
    $c->_csv_flash_error( $error );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  # Text::CSV Already errors on duplicate columns, so this is fine
  my @required = grep {/^user$|^value$|^date$|^organisation$/} @csv_headers;

  unless ( scalar( @required ) == 4 ) {
    $c->_csv_flash_error( 'Required columns not available' );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  my $csv_output = $csv->getline_hr_all( $fh );

  unless ( scalar( @$csv_output ) ) {
    $c->_csv_flash_error( "No data found" );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  for my $data ( @$csv_output ) {
    for my $key ( qw/ user value organisation / ) {
      unless ( defined $data->{$key} ) {
        $c->_csv_flash_error( "Undefined [$key] data found" );
        $c->redirect_to( '/admin/import/add' );
        return;
      }
    }
    if ( defined $data->{date} ) {
      my $dtp = DateTime::Format::Strptime->new( pattern => $date_format );
      my $dt_obj = $dtp->parse_datetime($data->{date});
      unless ( defined $dt_obj ) {
        $c->_csv_flash_error( "Undefined or incorrect format for [date] data found" );
        $c->redirect_to( '/admin/import/add' );
        return;
      }
      $data->{date} = $dt_obj;
    }
  }

  my $value_set;
  $c->schema->txn_do(
    sub {
      $value_set = $c->result_set->create({});

      $value_set->values->populate(
        [
          [ qw/ user_name purchase_value purchase_date org_name / ],
          ( map { [ @{$_}{qw/ user value date organisation /} ] } @$csv_output ),
        ]
      );
    }
  );

  unless ( defined $value_set ) {
    $c->_csv_flash_error( 'Error creating new Value Set' );
    $c->redirect_to( '/admin/import/add' );
    return;
  }

  $c->flash( success => 'Created Value Set' );
  $c->redirect_to( '/admin/import/' . $value_set->id );
}

sub _csv_flash_error {
  my ( $c, $error ) = @_;
  $error //= "An error occurred";

  $c->flash(
    error => $error,
    # If csv info is huge, this fails epically
    #csv_data => $c->param('csv'),
    date_format => $c->param('date_format'),
  );
}

sub get_user {
  my $c = shift;
  my $set_id = $c->param('set_id');
  my $user_name = $c->param('user');

  my $values_rs = $c->result_set->find($set_id)->values->search(
    {
      user_name => $user_name,
      ignore_value => 0,
    }
  );

  unless ( $values_rs->count > 0 ) {
    $c->flash( error => 'User not found or all values are ignored' );
    return $c->redirect_to( '/admin/import/' . $set_id );
  }

  my $lookup_result = $c->result_set->find($set_id)->lookups->find(
    { name => $user_name },
  );

  my $entity_id = $c->param('entity');

  my $users_rs = $c->schema->resultset('User');

  if ( defined $entity_id && $users_rs->find({ entity_id => $entity_id }) ) {
    if ( defined $lookup_result ) {
      $lookup_result->update({ entity_id => $entity_id });
    } else {
      $lookup_result = $c->result_set->find($set_id)->lookups->create(
        {
          name => $user_name,
          entity_id => $entity_id,
        },
      );
    }
  } elsif ( defined $entity_id ) {
    $c->stash( error => "User does not exist" );
  }

  $c->stash(
    users_rs => $users_rs,
    lookup => $lookup_result,
    user_name => $user_name,
  );
}

sub get_org {
  my $c = shift;
  my $set_id = $c->param('set_id');
  my $org_name = $c->param('org');

  my $values_rs = $c->result_set->find($set_id)->values->search(
    {
      org_name => $org_name,
      ignore_value => 0,
    }
  );

  unless ( $values_rs->count > 0 ) {
    $c->flash( error => 'Organisation not found or all values are ignored' );
    return $c->redirect_to( '/admin/import/' . $set_id );
  }

  my $lookup_result = $c->result_set->find($set_id)->lookups->find(
    { name => $org_name },
  );

  my $entity_id = $c->param('entity');

  my $orgs_rs = $c->schema->resultset('Organisation');

  if ( defined $entity_id && $orgs_rs->find({ entity_id => $entity_id }) ) {
    if ( defined $lookup_result ) {
      $lookup_result->update({ entity_id => $entity_id });
    } else {
      $lookup_result = $c->result_set->find($set_id)->lookups->create(
        {
          name => $org_name,
          entity_id => $entity_id,
        },
      );
    }
  } elsif ( defined $entity_id ) {
    $c->stash( error => "Organisation does not exist" );
  }

  $c->stash(
    orgs_rs => $orgs_rs,
    lookup => $lookup_result,
    org_name => $org_name,
  );
}

sub ignore_value {
  my $c = shift;
  my $set_id = $c->param('set_id');
  my $value_id = $c->param('value_id');

  my $set_result = $c->result_set->find($set_id);
  unless ( defined $set_result ) {
    $c->flash( error => "Set does not exist" );
    return $c->redirect_to( '/admin/import' );
  }

  my $value_result = $set_result->values->find($value_id);
  unless ( defined $value_result ) {
    $c->flash( error => "Value does not exist" );
    return $c->redirect_to( '/admin/import/' . $set_id );
  }

  $value_result->update({ ignore_value => $value_result->ignore_value ? 0 : 1 });

  $c->flash( success => "Updated value" );
  my $referer = $c->req->headers->header('Referer');
  return $c->redirect_to(
    defined $referer
    ? $c->url_for($referer)->path_query
    : '/admin/import/' . $set_id
  );
}

sub run_import {
  my $c = shift;
  my $set_id = $c->param('set_id');

  my $set_result = $c->result_set->find($set_id);
  unless ( defined $set_result ) {
    $c->flash( error => "Set does not exist" );
    return $c->redirect_to( '/admin/import' );
  }

  my $import_value_rs = $c->result_set->get_values($set_id, undef, undef);
  my $import_lookup = $c->result_set->get_lookups($set_id);
  my $entity_rs = $c->schema->resultset('Entity');

  $c->schema->txn_do(
    sub {
      for my $value_result ( $import_value_rs->all ) {
        my $user_lookup = $import_lookup->{ $value_result->user_name };
        my $org_lookup = $import_lookup->{ $value_result->org_name };
        my $value_lookup = $c->parse_currency( $value_result->purchase_value );

        if ( defined $user_lookup && defined $org_lookup && $value_lookup ) {
          my $user_entity = $entity_rs->find($user_lookup->{entity_id});
          my $org_entity = $entity_rs->find($org_lookup->{entity_id});
          my $distance = $c->get_distance_from_coords( $user_entity->type_object, $org_entity->type_object );
          my $transaction = $c->schema->resultset('Transaction')->create(
            {
              buyer => $user_entity,
              seller => $org_entity,
              value => $value_lookup * 100000,
              purchase_time => $value_result->purchase_date,
              distance => $distance,
            }
          );
          $value_result->update({transaction_id => $transaction->id });
        } else {
          $c->app->log->warn("Failed value import for value id [" . $value_result->id . "], ignoring");
        }
      }
    }
  );

  $c->flash( success => "Import completed for ready values" );
  my $referer = $c->req->headers->header('Referer');
  return $c->redirect_to(
    defined $referer
    ? $c->url_for($referer)->path_query
    : '/admin/import/' . $set_id
  );
}

1;
