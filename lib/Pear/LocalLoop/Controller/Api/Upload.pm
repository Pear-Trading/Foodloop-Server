package Pear::LocalLoop::Controller::Api::Upload;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

=head2 post_upload

Takes a file upload, with a file key of 'file2', and a json string under the
'json' key.

The json string should be an object, with the following keys:

=over

=item * transaction_value

The value of the transaction

=item * transaction_type

Is a value of 1, 2, or 3 - depending on the type of transaction.

=item * organisation_id

An ID of a valid organisation. used when transaction_type is 1 or 2.

=item * organisation_name

The name of an organisation. Used when transaction_type is 3.

=item * street_name

The street of an organisation, optional key. Used when transaction_type is 3.

=item * town

The village/town/city of an organisation. Used when transaction_type is 3.

=item * postcode

The postcode of an organisation, optional key. Used when transaction_Type is 3.

=back

=cut

has error_messages => sub {
  return {
    transactionAdditionType => {
      required => { message => 'transactionAdditionType is missing.', status => 400 },
      in => { message => 'transactionAdditionType is not a valid value.', status => 400 },
    },
    microCurrencyValue => {
      required => { message => 'microCurrencyValue is missing', status => 400 },
      number => { message => 'microCurrencyValue does not look like a number', status => 400 },
      gt_num => { message => 'microCurrencyValue cannot be equal to or less than zero', status => 400 },
    },
    file2 => {
      required => { message => 'No file uploaded', status => 400 },
    },
    addValidatedId => {
      required => { message => 'addValidatedId is missing', status => 400 },
      number => { message => 'organisation_id is not a number', status => 400 },
      in_resultset => { message => 'addValidatedId does not exist in the database', status => 400 },
    },
    addUnvalidatedId => {
      required => { message => 'addUnvalidatedId is missing', status => 400 },
      number => { message => 'addUnvalidatedId does not look like a number', status => 400 },
      in_resultset => { message => 'addUnvalidatedId does not exist in the database for the user', status => 400 },
    },
    organisationName => {
      required => { message => 'organisationName is missing', status => 400 },
    },
  };
};

sub post_upload {
  my $c = shift;
  my $self = $c;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;

  # Test for file before loading the JSON in to the validator
  $validation->required('file2');

  $validation->input( $c->stash->{api_json} );

  $validation->required('microCurrencyValue')->number->gt_num(0);
  $validation->required('transactionAdditionType')->in( 1, 2, 3 );

  # First pass of required items
  return $c->api_validation_error if $validation->has_error;

  my $type = $validation->param('transactionAdditionType');

  if ( $type == 1 ) {
    # Validated Organisation
    my $valid_org_rs = $c->schema->resultset('Organisation');
    $validation->required('addValidatedId')->number->in_resultset( 'organisationalid', $valid_org_rs );
  } elsif ( $type == 2 ) {
    # Unvalidated Organisation
    my $valid_org_rs = $c->schema->resultset('PendingOrganisation')->search({ usersubmitted_fk => $user->id });
    $validation->required('addUnvalidatedId')->number->in_resultset( 'pendingorganisationid', $valid_org_rs );
  } elsif ( $type == 3 ) {
    # Unknown Organisation
    $validation->required('organisationName');
    $validation->optional('streetName');
    $validation->optional('town');
    $validation->optional('postcode')->postcode;
  }

  return $c->api_validation_error if $validation->has_error;

  my $transactionAdditionType = $type;
  my $microCurrencyValue = $validation->param('microCurrencyValue');

  my $json = $c->stash->{api_json};

  my $userId = $user->id;
 
  my $file = $self->req->upload('file2');

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
  
  if ( $type == 1 ) {
    # Validated organisation
    $c->schema->resultset('Transaction')->create({
      buyeruserid_fk => $user->id,
      sellerorganisationid_fk => $validation->param('addValidatedId'),
      valuemicrocurrency => $microCurrencyValue,
      proofimage => $filename,
      timedatesubmitted => DateTime->now,
    });

    $file->move_to('images/' . $filename);
  } elsif ( $type == 2 ) {
    # Unvalidated Organisation
    $c->schema->resultset('PendingTransaction')->create({
      buyeruserid_fk => $user->id,
      pendingsellerorganisationid_fk => $validation->param('addUnvalidatedId'),
      valuemicrocurrency => $microCurrencyValue,
      proofimage => $filename,
      timedatesubmitted => DateTime->now,
    });

    $file->move_to('images/' . $filename);
  } elsif ( $type == 3 ) {
    my $organisationName = $validation->param('organisationName');
    my $streetName = $validation->param('streetName');
    my $town = $validation->param('town');
    my $postcode = $validation->param('postcode');

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

    my $pending_org = $c->schema->resultset('PendingOrganisation')->create({
      usersubmitted_fk => $user->id,
      timedatesubmitted => DateTime->now,
      name => $organisationName,
      fulladdress => $fullAddress,
      postcode => $postcode,
    });

    $c->schema->resultset('PendingTransaction')->create({
      buyeruserid_fk => $user->id,
      pendingsellerorganisationid_fk => $pending_org->pendingorganisationid,
      valuemicrocurrency => $microCurrencyValue,
      proofimage => $filename,
      timedatesubmitted => DateTime->now,
    });

    $file->move_to('images/' . $filename);
  }
  return $self->render( json => {
    success => Mojo::JSON->true,
    message => 'Upload Successful',
  });

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
