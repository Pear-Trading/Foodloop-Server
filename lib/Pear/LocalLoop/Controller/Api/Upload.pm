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
    search_name => {
      required => { message => 'search_name is missing', status => 400 },
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
    $validation->required('organisation_id')->number->in_resultset( 'id', $valid_org_rs );
  } elsif ( $type == 2 ) {
    # Unvalidated Organisation
    my $valid_org_rs = $c->schema->resultset('PendingOrganisation')->search({ submitted_by_id => $user->id });
    $validation->required('organisation_id')->number->in_resultset( 'id', $valid_org_rs );
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
      submitted_by => $user,
      submitted_at => DateTime->now,
      name         => $organisation_name,
      street_name  => $street_name,
      town         => $town,
      postcode     => $postcode,
    });

    $c->schema->resultset('PendingTransaction')->create({
      buyeruserid_fk => $user->id,
      pendingsellerorganisationid_fk => $pending_org->id,
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


# TODO Limit search results, possibly paginate them?
# TODO Search by location as well
sub post_search {
  my $c = shift;
  my $self = $c;

  my $validation = $c->validation;

  $validation->input( $c->stash->{api_json} );

  $validation->required('search_name');

  return $c->api_validation_error if $validation->has_error;

  my $search_name = $validation->param('search_name');

  my $valid_orgs_rs = $c->schema->resultset('Organisation')->search(
    { 'LOWER(name)' => { -like => '%' . lc $search_name . '%' } },
  );

  my $pending_orgs_rs = $c->stash->{api_user}->pending_organisations->search(
    { 'LOWER(name)' => { -like => '%' . lc $search_name . '%' } },
  );

  my @valid_orgs = (
    map {{
        id => $_->id,
        name => $_->name,
        street_name => $_->street_name,
        town => $_->town,
        postcode => $_->postcode,
    }} $valid_orgs_rs->all
  );

  my @pending_orgs = (
    map {{
        id => $_->id,
        name => $_->name,
        street_name => $_->street_name,
        town => $_->town,
        postcode => $_->postcode,
    }} $pending_orgs_rs->all
  );

  return $self->render( json => {
    success => Mojo::JSON->true,
    validated => \@valid_orgs,
    unvalidated => \@pending_orgs,
  });
}

1;
