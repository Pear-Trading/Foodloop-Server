package Pear::LocalLoop::Controller::Api::Admin;
use Mojo::Base 'Mojolicious::Controller';

has error_messages => sub {
  return {
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
  my $self = $c;

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

  my $pending_transaction_rs = $pending_org->pending_transactions;

  while ( my $pending_transaction = $pending_transaction_rs->next ) {
    $valid_org->create_related(
      'transactions', {
        buyeruserid_fk     => $pending_transaction->buyeruserid_fk,
        valuemicrocurrency => $pending_transaction->valuemicrocurrency,
        proofimage         => $pending_transaction->proofimage,
        timedatesubmitted  => $pending_transaction->timedatesubmitted,
      }
    );
  }

  $pending_org->delete;

  return $self->render(
    json => {
      success => Mojo::JSON->true,
      message => 'Successfully Approved Organisation',
    },
    status => 200,
  );
}


sub post_admin_merge {
  my $self = shift;

  my $userId = $self->get_active_user_id();
  if ( ! $self->is_admin($userId) ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'You are not an admin.',
    },
    status => 403,); #Forbidden request   
  }

  my $json = $self->req->json;
  if ( ! defined $json ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'JSON is missing.',
    },
    status => 400,); #Malformed request   
  }

  my $unvalidatedOrganisationId = $json->{unvalidatedOrganisationId};
  if ( ! defined $unvalidatedOrganisationId ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'unvalidatedOrganisationId is missing.',
    },
    status => 400,); #Malformed request   
  }
  elsif (! Scalar::Util::looks_like_number($unvalidatedOrganisationId)){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'unvalidatedOrganisationId does not look like a number.',
    },
    status => 400,); #Malformed request   
  }

  my $validatedOrganisationId = $json->{validatedOrganisationId};
  if ( ! defined $validatedOrganisationId ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'validatedOrganisationId is missing.',
    },
    status => 400,); #Malformed request   
  }
  elsif (! Scalar::Util::looks_like_number($validatedOrganisationId)){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'validatedOrganisationId does not look like a number.',
    },
    status => 400,); #Malformed request   
  }

  #FIXME This requires mutual exclusion.

  my $doesUnvalidatedIdNotExist = ($self->db->selectrow_array("SELECT COUNT(*) FROM PendingOrganisations WHERE PendingOrganisationId = ?", undef, ($unvalidatedOrganisationId)) == 0);
  if ($doesUnvalidatedIdNotExist) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'unvalidatedOrganisationId does not exist in the database.',
    },
    status => 400,); #Malformed request 
  }

  my $doesValidatedIdNotExist = ($self->db->selectrow_array("SELECT COUNT(*) FROM Organisations WHERE OrganisationalId = ?", undef, ($validatedOrganisationId)) == 0);
  if ($doesValidatedIdNotExist) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'validatedOrganisationId does not exist in the database.',
    },
    status => 400,); #Malformed request 
  }
  

  #FIXME there may be race conditions here, so may get the wrong number, mutux is needed.
  my $statementSelectPendingTrans = $self->db->prepare("SELECT BuyerUserId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted FROM PendingTransactions WHERE PendingSellerOrganisationId_FK = ?");
  $statementSelectPendingTrans->execute($unvalidatedOrganisationId);

  my $statementInsTrans = $self->db->prepare("INSERT INTO Transactions (BuyerUserId_FK, SellerOrganisationId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted) VALUES (?, ?, ?, ?, ?)");

  #Move all transactions from pending onto verified.
  while (my ($buyerUserId, $value, $imgName, $timeDate) = $statementSelectPendingTrans->fetchrow_array()) {
    $statementInsTrans->execute($buyerUserId, $validatedOrganisationId, $value, $imgName, $timeDate);
  }

  #Delete transactions first, so there is no dependancy when deleting the row from PendingOrganisations.
  $self->db->prepare("DELETE FROM PendingTransactions WHERE PendingSellerOrganisationId_FK = ?")->execute($unvalidatedOrganisationId);
  $self->db->prepare("DELETE FROM PendingOrganisations WHERE PendingOrganisationId = ?")->execute($unvalidatedOrganisationId);

  $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
  return $self->render( json => {
    success => Mojo::JSON->true,
  },
  status => 200,);  

}



1;

