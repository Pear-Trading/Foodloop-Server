package Pear::LocalLoop::Controller::Api::Organisation;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has error_messages => sub {
  return {
    sector => {
      required => { message => 'No sector sent.', status => 400 },
    },
  };
};

sub post_payroll {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  return $c->api_validation_error if $validation->has_error;

  my $user_rs = $c->schema->resultset('User')->search({
    id => { "!=" => $user->id },
  });

  $validation->required('entryperiod');
  $validation->required('employeeamount');
  $validation->required('localemployeeamount');
  $validation->required('grosspayroll');
  $validation->optional('payrollincometax');
  $validation->optional('payrollemployeeni');
  $validation->optional('payrollemployerni');
  $validation->optional('payrolltotalpension');
  $validation->optional('payrollotherbenefit');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entryperiod'),
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Submitted Payroll Info Successfully',
  });
}

sub post_supplier {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  return $c->api_validation_error if $validation->has_error;

  my $user_rs = $c->schema->resultset('User')->search({
    id => { "!=" => $user->id },
  });

  $validation->required('entryperiod');
  $validation->optional('postcode')->postcode;
  $validation->optional('supplierbusinessname');
  $validation->optional('monthlyspend');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entryperiod'),
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Submitted Payroll Info Successfully',
  });
}

sub post_employee {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  return $c->api_validation_error if $validation->has_error;

  my $user_rs = $c->schema->resultset('User')->search({
    id => { "!=" => $user->id },
  });

  $validation->required('entryperiod');
  $validation->optional('employeeno');
  $validation->optional('employeeincometax');
  $validation->optional('employeegrosswage');
  $validation->optional('employeeni');
  $validation->optional('employeepension');
  $validation->optional('employeeotherbenefit');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entryperiod'),
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Submitted Payroll Info Successfully',
  });
}

1;
