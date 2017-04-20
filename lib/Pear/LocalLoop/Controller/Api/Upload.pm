package Pear::LocalLoop::Controller::Api::Upload;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

=head2 post_upload

Takes a file upload, with a file key of 'file', and a json string under the
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
    transaction_type => {
      required => { message => 'transaction_type is missing.', status => 400 },
      in => { message => 'transaction_type is not a valid value.', status => 400 },
    },
    transaction_value => {
      required => { message => 'transaction_value is missing', status => 400 },
      number => { message => 'transaction_value does not look like a number', status => 400 },
      gt_num => { message => 'transaction_value cannot be equal to or less than zero', status => 400 },
    },
    file => {
      required => { message => 'No file uploaded', status => 400 },
      upload => { message => 'file key does not contain a file', status => 400 },
      filetype => { message => 'File must be of type image/jpeg', status => 400 },
    },
    organisation_id => {
      required => { message => 'organisation_id is missing', status => 400 },
      number => { message => 'organisation_id is not a number', status => 400 },
      in_resultset => { message => 'organisation_id does not exist in the database', status => 400 },
    },
    organisation_name => {
      required => { message => 'organisation_name is missing', status => 400 },
    },
  };
};

sub post_upload {
  my $c = shift;
  my $self = $c;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;

  # Test for file before loading the JSON in to the validator
  $validation->required('file')->upload->filetype('image/jpeg');

  $validation->input( $c->stash->{api_json} );

  $validation->required('transaction_value')->number->gt_num(0);
  $validation->required('transaction_type')->in( 1, 2, 3 );

  # First pass of required items
  return $c->api_validation_error if $validation->has_error;

  my $type = $validation->param('transaction_type');

  if ( $type == 1 ) {
    # Validated Organisation
    my $valid_org_rs = $c->schema->resultset('Organisation');
    $validation->required('organisation_id')->number->in_resultset( 'organisationalid', $valid_org_rs );
  } elsif ( $type == 2 ) {
    # Unvalidated Organisation
    my $valid_org_rs = $c->schema->resultset('PendingOrganisation')->search({ usersubmitted_fk => $user->id });
    $validation->required('organisation_id')->number->in_resultset( 'pendingorganisationid', $valid_org_rs );
  } elsif ( $type == 3 ) {
    # Unknown Organisation
    $validation->required('organisation_name');
    $validation->optional('street_name');
    $validation->optional('town');
    $validation->optional('postcode')->postcode;
  }

  return $c->api_validation_error if $validation->has_error;

  my $transaction_value = $validation->param('transaction_value');

  my $file = $validation->param('file');

  my $ext = '.jpg';
  my $uuid = Data::UUID->new->create_str;
  my $filename = $uuid . $ext;

  if ( $type == 1 ) {
    # Validated organisation
    $c->schema->resultset('Transaction')->create({
      buyeruserid_fk => $user->id,
      sellerorganisationid_fk => $validation->param('organisation_id'),
      valuemicrocurrency => $transaction_value,
      proofimage => $filename,
      timedatesubmitted => DateTime->now,
    });

    $file->move_to('images/' . $filename);
  } elsif ( $type == 2 ) {
    # Unvalidated Organisation
    $c->schema->resultset('PendingTransaction')->create({
      buyeruserid_fk => $user->id,
      pendingsellerorganisationid_fk => $validation->param('organisation_id'),
      valuemicrocurrency => $transaction_value,
      proofimage => $filename,
      timedatesubmitted => DateTime->now,
    });

    $file->move_to('images/' . $filename);
  } elsif ( $type == 3 ) {
    my $organisation_name = $validation->param('organisation_name');
    my $street_name = $validation->param('street_name');
    my $town = $validation->param('town');
    my $postcode = $validation->param('postcode');

    my $fullAddress = "";

    if ( defined $street_name && ! ($street_name =~ m/^\s*$/) ){
      $fullAddress = $street_name;
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
      name => $organisation_name,
      fulladdress => $fullAddress,
      postcode => $postcode,
    });

    $c->schema->resultset('PendingTransaction')->create({
      buyeruserid_fk => $user->id,
      pendingsellerorganisationid_fk => $pending_org->pendingorganisationid,
      valuemicrocurrency => $transaction_value,
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
