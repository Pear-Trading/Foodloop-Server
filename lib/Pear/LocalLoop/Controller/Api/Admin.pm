package Pear::LocalLoop::Controller::Api::Admin;
use Mojo::Base 'Mojolicious::Controller';

has error_messages => sub {
  return {
    target_organisation_id => {
      required => { message => 'target_organisation_id is missing', status => 400 },
      number => { message => 'target_organisation_id is not a number', status => 400 },
      in_resultset => { message => 'target_organisation_id does not exist in the database', status => 400 },
    },
    pending_organisation_id => {
      required => { message => 'pending_organisation_id is missing', status => 400 },
      number => { message => 'pending_organisation_id is not a number', status => 400 },
      in_resultset => { message => 'pending_organisation_id does not exist in the database', status => 400 },
    },
    postcode => {
      postcode => { message => 'postcode is not a valid uk postcode', status => 400 },
    },
  };
};

sub auth {
  my $c = shift;

  if ( defined $c->stash->{ api_user }->administrator ) {
    return 1;
  }

  $c->render(
    json => {
      success => Mojo::JSON->false,
      message => 'Not Authorised',
    },
    status => 403,
  );
  return 0;
}

sub post_admin_approve {
  my $c = shift;

  my $validation = $c->validation;

  $validation->input( $c->stash->{api_json} );

  my $pending_org_rs = $c->schema->resultset('PendingOrganisation');
  $validation->required('pending_organisation_id')->number->in_resultset('id', $pending_org_rs);
  $validation->optional('name');
  $validation->optional('street_name');
  $validation->optional('town');
  $validation->optional('postcode')->postcode;

  return $c->api_validation_error if $validation->has_error;

  my $pending_org = $pending_org_rs->find( $validation->param('pending_organisation_id') );
 
  my $valid_org = $c->schema->resultset('Organisation')->create({
    name        => $validation->param('name') || $pending_org->name,
    street_name => $validation->param('street_name') || $pending_org->street_name,
    town        => $validation->param('town') || $pending_org->town,
    postcode    => $validation->param('postcode') || $pending_org->postcode,
  });

  $c->copy_transactions_and_delete( $pending_org, $valid_org );

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      message => 'Successfully Approved Organisation',
    },
    status => 200,
  );
}


sub post_admin_merge {
  my $c = shift;

  my $validation = $c->validation;

  $validation->input( $c->stash->{api_json} );

  my $pending_org_rs = $c->schema->resultset('PendingOrganisation');
  $validation->required('pending_organisation_id')->number->in_resultset('id', $pending_org_rs);

  my $valid_org_rs = $c->schema->resultset('Organisation');
  $validation->required('target_organisation_id')->number->in_resultset('id', $valid_org_rs);

  return $c->api_validation_error if $validation->has_error;

  my $pending_org = $pending_org_rs->find( $validation->param('pending_organisation_id') );
  my $target_org = $valid_org_rs->find( $validation->param('target_organisation_id') );
 
  $c->copy_transactions_and_delete( $pending_org, $target_org );

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      message => 'Successfully Merged Organisations',
    },
    status => 200,
  );  
}

1;

