package Pear::LocalLoop::Controller::Portal;
use Mojo::Base 'Mojolicious::Controller';

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

  my $user = $c->current_user;
  my $validation = $c->validation;

  $validation->required('file')->upload->filetype('image/jpeg');
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
  my $upload = $validation->param('file');

  my $file = $c->store_file_from_upload( $upload );

  if ( $type == 1 ) {
    # Validated organisation
    $c->schema->resultset('Transaction')->create({
      buyeruserid_fk => $user->id,
      sellerorganisationid_fk => $validation->param('organisation_id'),
      valuemicrocurrency => $transaction_value,
      proof_image => $file,
      timedatesubmitted => DateTime->now,
    });
  } elsif ( $type == 2 ) {
    # Unvalidated Organisation
    $c->schema->resultset('PendingTransaction')->create({
      buyeruserid_fk => $user->id,
      pendingsellerorganisationid_fk => $validation->param('organisation_id'),
      valuemicrocurrency => $transaction_value,
      proof_image => $file,
      timedatesubmitted => DateTime->now,
    });
  } elsif ( $type == 3 ) {
    my $organisation_name = $validation->param('organisation_name');
    my $street_name = $validation->param('street_name');
    my $town = $validation->param('town');
    my $postcode = $validation->param('postcode');

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
      proof_image => $file,
      timedatesubmitted => DateTime->now,
    });
  }
  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Upload Successful',
  });
}

1;
