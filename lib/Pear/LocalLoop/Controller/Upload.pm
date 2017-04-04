package Pear::LocalLoop::Controller::Upload;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

=head2 post_upload

Takes a file upload, with a file key of 'file2', and a json string under the
'json' key.

The json string should be an object, with the following keys:

=over

=item * microCurrencyValue

The value of the transaction

=item * transactionAdditionType

Is a value of 1, 2, or 3 - depending on the type of transaction.

=item * addValidatedId

An ID of a valid organisation. used when transactionAdditionType is 1.

=item * addUnvalidatedId

An ID of an unvalidated organisation. Used when transactionAdditionType is 2.

=item * organisationName

The name of an organisation. Used when transactionAdditionType is 3.

=back

=cut

sub post_upload {
  my $self = shift;

  my $userId = $self->get_active_user_id();

  my $json = $self->param('json');
  if ( ! defined $json ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'JSON is missing.',
    },
    status => 400,); #Malformed request   
  }

  $json = Mojo::JSON::decode_json($json);
  $self->app->log->debug( "JSON: " . Dumper $json );
  
  my $microCurrencyValue = $json->{microCurrencyValue};
  if ( ! defined $microCurrencyValue ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'microCurrencyValue is missing.',
    },
    status => 400,); #Malformed request   
  }
  #Is valid number
  elsif (! Scalar::Util::looks_like_number($microCurrencyValue)){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'microCurrencyValue does not look like a number.',
    },
    status => 400,); #Malformed request   
  }
  #Is the number range valid.
  elsif ($microCurrencyValue <= 0){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'microCurrencyValue cannot be equal to or less than zero.',
    },
    status => 400,); #Malformed request   
  }

  my $transactionAdditionType = $json->{transactionAdditionType};
  if ( ! defined $transactionAdditionType ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'transactionAdditionType is missing.',
    },
    status => 400,); #Malformed request   
  }

  my $file = $self->req->upload('file2');
  $self->app->log->debug( "file: " . Dumper $file );

  if (! defined $file) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'no file uploaded.',
    },
    status => 400,); #Malformed request   
  }

  my $ext = '.jpg';
  my $uuid = Data::UUID->new->create_str;
  my $filename = $uuid . $ext;

  #TODO Check for valid image file.
#  my $headers = $file->headers->content_type;
#  $self->app->log->debug( "content type: " . Dumper $headers );
  #Is content type wrong?
#  if ($headers ne 'image/jpeg') {
#    return $self->render( json => {
#    success => Mojo::JSON->false,
#      message => 'Wrong image extension!',
#    }, status => 400);
#  };
  
  #Add validated organisation.
  if ($transactionAdditionType == 1){

    my $addValidatedId = $json->{addValidatedId};
    if (! defined $addValidatedId){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'addValidatedId is missing.',
      },
      status => 400,); #Malformed request   
    }

    if (! $self->does_organisational_id_exist($addValidatedId)){
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'addValidatedId does not exist in the database.',
      },
      status => 400,); #Malformed request   
    }
  
    my $time = time();
    my $statement = $self->db->prepare("INSERT INTO Transactions (BuyerUserId_FK, SellerOrganisationId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted) VALUES (?, ?, ?, ?, ?)");
    my $rowsAdded = $statement->execute($userId, $addValidatedId, $microCurrencyValue, $filename, $time);
    
    #It was successful.
    if ($rowsAdded != 0) {
      $file->move_to('images/' . $filename);
      $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->true,
        message => 'Added transaction for validated organisation.',
      },
      status => 200,);
    }
    #TODO Untested, not quite sure how to test it.
    else {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'An unknown error occurred when adding the transaction.',
      },
      status => 500,);   
    } 
  }
  #2 and 3 are similar by the adding of a transaction at the end.
  elsif ($transactionAdditionType == 2 || $transactionAdditionType == 3){

    my $unvalidatedOrganisationId = undef;

    if ($transactionAdditionType == 2){
      $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);

      $unvalidatedOrganisationId = $json->{addUnvalidatedId};
      if (! defined $unvalidatedOrganisationId){
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'addUnvalidatedId is missing.',
        },
        status => 400,); #Malformed request   
      } 
      elsif (! Scalar::Util::looks_like_number($unvalidatedOrganisationId)){
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'addUnvalidatedId does not look like a number.',
        },
        status => 400,); #Malformed request   
      }

      my ($existsRef) = $self->db->selectrow_array("SELECT COUNT(PendingOrganisationId) FROM PendingOrganisations WHERE PendingOrganisationId = ? AND UserSubmitted_FK = ?",undef,($unvalidatedOrganisationId, $userId));
      if ($existsRef == 0) {
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'addUnvalidatedId does not exist in the database for the user.',
        },
        status => 400,); #Malformed request 
      }

    }
    #type need to add a organisation for type 3.
    else{ # ($transactionAdditionType == 3)
      $self->app->log->debug('Path: file:' . __FILE__ . ', line: ' . __LINE__);

      #TODO more validation.
      my $organisationName = $json->{organisationName};
      if (! defined $organisationName){
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'organisationName is missing.',
        },
        status => 400,); #Malformed request   
      }      

      #TODO validation.
      #TODO check which ones are present.
      my $streetName = $json->{streetName};
      my $town = $json->{town};
      my $postcode = $json->{postcode};

      ($unvalidatedOrganisationId) = $self->db->selectrow_array("SELECT MAX(PendingOrganisationId) FROM PendingOrganisations",undef,());
      if (defined $unvalidatedOrganisationId){
        $unvalidatedOrganisationId++;
      }
      else{
        $unvalidatedOrganisationId = 1;
      }

      my $fullAddress = "";
      
      if ( defined $streetName && ! ($streetName =~ m/^\s*$/) ){
        $fullAddress = $streetName;
      }

      if ( defined $town && ! ($town =~ m/^\s*$/) ){
        if ($fullAddress eq ""){
          $fullAddress = $town;
        }
        else{
          $fullAddress = $fullAddress . ", " . $town;          
        }

      }

      my $statement = $self->db->prepare("INSERT INTO PendingOrganisations (PendingOrganisationId, UserSubmitted_FK, TimeDateSubmitted, Name, FullAddress, Postcode) VALUES (?, ?, ?, ?, ?, ?)");
      my $rowsAdded = $statement->execute($unvalidatedOrganisationId,$userId,time(),$organisationName,$fullAddress,$postcode);

      #TODO, untested. It could not be added for some reason. Most likely race conditions.
      if ($rowsAdded == 0) {
        $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
        return $self->render( json => {
          success => Mojo::JSON->false,
          message => 'An unknown error occurred when adding the transaction.',
        },
        status => 500,);   
      } 
    }


    my $statement2 = $self->db->prepare("INSERT INTO PendingTransactions (BuyerUserId_FK, PendingSellerOrganisationId_FK, ValueMicroCurrency, ProofImage, TimeDateSubmitted) VALUES (?, ?, ?, ?, ?)");
    my $rowsAdded2 = $statement2->execute($userId, $unvalidatedOrganisationId, $microCurrencyValue, $filename, time());

    if ($rowsAdded2 != 0) {
      $file->move_to('images/' . $filename);
      $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
    
      my $returnedJson = {
        success => Mojo::JSON->true,
        message => 'Added transaction for unvalidated organisation.',
      };

      if ($transactionAdditionType == 3){
        $returnedJson->{unvalidatedOrganisationId} = $unvalidatedOrganisationId;
      }

      return $self->render( json => $returnedJson,
      status => 200,);    
    }
    else {
      $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
      return $self->render( json => {
        success => Mojo::JSON->false,
        message => 'An unknown error occurred when adding the transaction.',
      },
      status => 500,);   
    } 
  }
  else{
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'transactionAdditionType is not a valid value.',
    },
    status => 400,); #Malformed request   
  }

}


#TODO this should limit the number of responses returned, when location is implemented that would be the main way of filtering.
sub post_search {
  my $self = shift;
  my $userId = $self->get_active_user_id();

  my $json = $self->req->json;
  if ( ! defined $json ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'JSON is missing.',
    },
    status => 400,); #Malformed request   
  }

  my $searchName = $json->{searchName};
  if ( ! defined $searchName ) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'searchName is missing.',
    },
    status => 400,); #Malformed request   
  }
  #Is blank
  elsif  ( $searchName =~ m/^\s*$/) {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'searchName is blank.',
    },
    status => 400,); #Malformed request   
  }

  #Currently ignored
  #TODO implement further. 
  my $searchLocation = $json->{searchLocation};

  my @validatedOrgs = ();
  {
    my $statementValidated = $self->db->prepare("SELECT OrganisationalId, Name, FullAddress, PostCode FROM Organisations WHERE UPPER( Name ) LIKE ?");
    $statementValidated->execute('%'. uc $searchName.'%');

    while (my ($id, $name, $address, $postcode) = $statementValidated->fetchrow_array()) {
      push(@validatedOrgs, $self->create_hash($id,$name,$address,$postcode));
    }
  }

  $self->app->log->debug( "Orgs: " . Dumper @validatedOrgs );

  my @unvalidatedOrgs = ();
  {
    my $statementUnvalidated = $self->db->prepare("SELECT PendingOrganisationId, Name, FullAddress, Postcode FROM PendingOrganisations WHERE UPPER( Name ) LIKE ? AND UserSubmitted_FK = ?");
    $statementUnvalidated->execute('%'. uc $searchName.'%', $userId);

    while (my ($id, $name, $fullAddress, $postcode) = $statementUnvalidated->fetchrow_array()) {
      push(@unvalidatedOrgs, $self->create_hash($id, $name, $fullAddress, $postcode));
    }
  }
  
  $self->app->log->debug( "Non Validated Orgs: " . Dumper @unvalidatedOrgs );
  $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
  return $self->render( json => {
    success => Mojo::JSON->true,
    unvalidated => \@unvalidatedOrgs,
    validated => \@validatedOrgs,
  },
  status => 200,);    

}

1;
