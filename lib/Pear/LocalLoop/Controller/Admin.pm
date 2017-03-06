package Pear::LocalLoop::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;


sub post_admin_approve {
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


  my ($id, $name, $fullAddress, $postcode) = $self->db->selectrow_array("SELECT PendingOrganisationId, Name, FullAddress, Postcode FROM PendingOrganisations WHERE PendingOrganisationId = ?", undef, ($unvalidatedOrganisationId));

  #It does not exist.
  if (! defined $id) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'the specified unvalidatedOrganisationId does not exist.',
    },
    status => 400,); #Malformed request 
  }


  my $nameJson = $json->{name};
  if (defined $nameJson) {
    $name = $nameJson;
  }

  my $fullAddressJson = $json->{fullAddress};
  if (defined $fullAddressJson) {
    $fullAddress = $fullAddressJson;
  }

  my $postCodeJson = $json->{postCode};
  if (defined $postCodeJson) {
    $postcode = $postCodeJson;
  }
  

  #FIXME there may be race conditions here, so may get the wrong number, mutux is needed.
  my $statementInsOrg = $self->db->prepare("INSERT INTO Organisations (Name, FullAddress, PostCode) VALUES (?, ?, ?)");
  $statementInsOrg->execute($name, $fullAddress, $postcode);
  my $organisationalId = $self->db->last_insert_id(undef,undef, "Organisations", "OrganisationalId") . "\n";
  #print "OrgId: " . $organisationalId . "\n";

  my $statementSelectPendingTrans = $self->db->prepare("SELECT BuyerUserId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted FROM PendingTransactions WHERE PendingSellerOrganisationId_FK = ?");
  $statementSelectPendingTrans->execute($unvalidatedOrganisationId);

  my $statementInsTrans = $self->db->prepare("INSERT INTO Transactions (BuyerUserId_FK, SellerOrganisationId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted) VALUES (?, ?, ?, ?, ?)");

  #Move all transactions from pending onto verified.
  while (my ($buyerUserId, $value, $imgName, $timeDate) = $statementSelectPendingTrans->fetchrow_array()) {
    $statementInsTrans->execute($buyerUserId, $organisationalId, $value, $imgName, $timeDate);
  }

  #Delete transactions first, so there is no dependancy when deleting the row from PendingOrganisations.
  $self->db->prepare("DELETE FROM PendingTransactions WHERE PendingSellerOrganisationId_FK = ?")->execute($unvalidatedOrganisationId);
  $self->db->prepare("DELETE FROM PendingOrganisations WHERE PendingOrganisationId = ?")->execute($unvalidatedOrganisationId);

  $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
  return $self->render( json => {
    success => Mojo::JSON->true,
    validatedOrganisationId => $organisationalId,
  },
  status => 200,);  

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

