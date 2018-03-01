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

=item * purchase_time

Is a DateTime value submitted for when the receipt is from.

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
      required => { message => 'transaction type is missing.', status => 400 },
      in => { message => 'transaction type is not a valid value.', status => 400 },
    },
    transaction_value => {
      required => { message => 'transaction amount is missing', status => 400 },
      number => { message => 'transaction amount does not look like a number', status => 400 },
      gt_num => { message => 'transaction amount cannot be equal to or less than zero', status => 400 },
    },
    purchase_time => {
      required => { message => 'purchase time is missing', status => 400 },
      is_full_iso_datetime => { message => 'purchase time is in incorrect format', status => 400 },
    },
    file => {
      required => { message => 'No file uploaded', status => 400 },
      upload => { message => 'file key does not contain a file', status => 400 },
      filetype => { message => 'File must be of type image/jpeg', status => 400 },
    },
    organisation_id => {
      required => { message => 'existing organisation ID is missing', status => 400 },
      number => { message => 'organisation ID is not a number', status => 400 },
      in_resultset => { message => 'organisation ID does not exist in the database', status => 400 },
    },
    organisation_name => {
      required => { message => 'organisation name is missing', status => 400 },
    },
    category => {
      in_resultset => { message => 'Category is invalid', status => 400 },
    },
    town => {
      required => { message => 'town/city is missing', status => 400 },
    },
    search_name => {
      required => { message => 'search name is missing', status => 400 },
    },
    postcode => {
      postcode => { message => 'postcode must be valid', status => 400 },
    },
  };
};

sub post_upload {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;

  # Test for file before loading the JSON in to the validator
  $validation->optional('file')->upload->filetype('image/jpeg');

  $validation->input( $c->stash->{api_json} );

  $validation->required('transaction_value')->number->gt_num(0);
  $validation->required('transaction_type')->in( 1, 2, 3 );

  #Check a proper purchase time was submitted
  $validation->optional('purchase_time')->is_full_iso_datetime;
  $validation->optional('category')->in_resultset( 'id', $c->schema->resultset('Category'));
  $validation->optional('essential');

  # First pass of required items
  return $c->api_validation_error if $validation->has_error;

  my $type = $validation->param('transaction_type');

  my $organisation;

  if ( $type == 1 ) {
    # Validated Organisation
    my $valid_org_rs = $c->schema->resultset('Organisation')->search({
      pending => 0,
      entity_id => { "!=" => $user->entity_id },
     });
    $validation->required('organisation_id')->number->in_resultset( 'id', $valid_org_rs );

    return $c->api_validation_error if $validation->has_error;

    $organisation = $valid_org_rs->find( $validation->param('organisation_id') );

  } elsif ( $type == 2 ) {
    # Unvalidated Organisation
    my $valid_org_rs = $c->schema->resultset('Organisation')->search({
      submitted_by_id => $user->id,
      pending => 1,
      entity_id => { "!=" => $user->entity_id },
    });
    $validation->required('organisation_id')->number->in_resultset( 'id', $valid_org_rs );

    return $c->api_validation_error if $validation->has_error;

    $organisation = $valid_org_rs->find( $validation->param('organisation_id') );

  } elsif ( $type == 3 ) {
    # Unknown Organisation
    $validation->required('organisation_name');
    $validation->optional('street_name');
    $validation->required('town');
    $validation->optional('postcode')->postcode;

    return $c->api_validation_error if $validation->has_error;

    my $location = $c->get_location_from_postcode(
      $validation->param('postcode'),
      'organisation',
    );

    my $entity = $c->schema->resultset('Entity')->create_org({
      submitted_by_id => $user->id,
      name            => $validation->param('organisation_name'),
      street_name     => $validation->param('street_name'),
      town            => $validation->param('town'),
      postcode        => $validation->param('postcode'),
      ( defined $location ? ( %$location ) : ( latitude => undef, longitude => undef ) ),
      pending         => 1,
    });
    $organisation = $entity->organisation;
  }

  unless ( defined $organisation ) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => 'Error Finding Organisation',
        error   => 'organisation_error',
      },
      status => 400,
    );
  }

  my $transaction_value = $validation->param('transaction_value');
  my $upload = $validation->param('file');
  my $purchase_time = $c->parse_iso_datetime($validation->param('purchase_time') || '');
  $purchase_time ||= DateTime->now();
  my $file = defined $upload ? $c->store_file_from_upload( $upload ) : undef;
  my $category = $validation->param('category');
  my $essential = $validation->param('essential');
  my $distance = $c->get_distance_from_coords( $user->entity->type_object, $organisation );

  my $new_transaction = $organisation->entity->create_related(
    'sales',
    {
      buyer => $user->entity,
      value => $transaction_value * 100000,
      ( defined $file ? ( proof_image => $file ) : () ),
      purchase_time => $c->format_db_datetime($purchase_time),
      distance => $distance,
      essential => ( defined $essential ? $essential : undef ),
    }
  );

  unless ( defined $new_transaction ) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        message => 'Error Adding Transaction',
        error   => 'transaction_error',
      },
      status => 400,
    );
  }

  if ( defined $category ) {
    $c->schema->resultset('TransactionCategory')->create({
      category_id => $category,
      transaction_id => $new_transaction->id,
    });
  }

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Upload Successful',
  });
}

sub post_category {
  my $c = shift;
  my $self = $c;

  my $categories = { ids => [], names => [] };

  my $category_rs = $c->schema->resultset('Category');

  for ( $category_rs->all ) {
    push @{ $categories->{ ids } }, $_->get_column('id');
    push @{ $categories->{ names } }, $_->get_column('name');
  }

  return $self->render( json => {
    success => Mojo::JSON->true,
    categories => $categories,
  });
}

# TODO Limit search results, possibly paginate them?
# TODO Search by location as well
sub post_search {
  my $c = shift;
  my $self = $c;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;

  $validation->input( $c->stash->{api_json} );

  $validation->required('search_name');

  return $c->api_validation_error if $validation->has_error;

  my $search_name = $validation->param('search_name');

  my $search_stmt = [ 'LOWER("name") LIKE ?', '%' . lc $search_name . '%' ];

  my $org_rs = $c->schema->resultset('Organisation');
  my $valid_orgs_rs = $org_rs->search({
    pending => 0,
    entity_id => { "!=" => $user->entity_id },
  })->search(
    \$search_stmt,
  );

  my $pending_orgs_rs = $org_rs->search({
      pending => 1,
      submitted_by_id => $c->stash->{api_user}->id,
      entity_id => { "!=" => $user->entity_id },
    })->search(
    \$search_stmt,
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
