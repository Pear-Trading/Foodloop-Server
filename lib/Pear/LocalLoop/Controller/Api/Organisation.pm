package Pear::LocalLoop::Controller::Api::Organisation;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has error_messages => sub {
  return {
    entryperiod => {
      required => { message => 'No entry period sent.', status => 400 },
    },
    employeeamount => {
      required => { message => 'No employee amount sent.', status => 400 },
    },
    localemployeeamount => {
      required => { message => 'No local employee amount sent.', status => 400 },
    },
    grosspayroll => {
      required => { message => 'No gross payroll sent.', status => 400 },
    },
    payrollincometax => {
      required => { message => 'no payroll income tax sent.', status => 400 },
    },
    payrollemployeeni => {
      required => { message => 'no payroll employee ni sent.', status => 400 },
    },
    payrollemployerni => {
      required => { message => 'no payroll employer ni sent.', status => 400 },
    },
    payrolltotalpension => {
      required => { message => 'no payroll total pension sent.', status => 400 },
    },
    payrollotherbenefit => {
      required => { message => 'no payroll other benefit sent.', status => 400 },
    },
    supplierbusinessname => {
      required => { message => 'no supplier business name sent.', status => 400 },
    },
    postcode => {
      required => { message => 'no postcode sent.', status => 400 },
      postcode => { message => 'postcode must be valid', status => 400 },
    },
    monthlyspend => {
      required => { message => 'no monthly spend sent.', status => 400 },
    },
    employeeno => {
      required => { message => 'no employee no sent.', status => 400 },
    },
    employeeincometax => {
      required => { message => 'no employee income tax sent.', status => 400 },
    },
    employeegrosswage => {
      required => { message => 'no employee gross wage sent.', status => 400 },
    },
    employeeni => {
      required => { message => 'no employee ni sent.', status => 400 },
    },
    employeepension => {
      required => { message => 'no employee pension sent.', status => 400 },
    },
    employeeotherbenefit => {
      required => { message => 'no employee other benefits sent.', status => 400 },
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
  $validation->required('payrollincometax');
  $validation->required('payrollemployeeni');
  $validation->required('payrollemployerni');
  $validation->required('payrolltotalpension');
  $validation->required('payrollotherbenefit');

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
  $validation->required('postcode')->postcode;
  $validation->required('supplierbusinessname');
  $validation->required('monthlyspend');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entryperiod'),
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Submitted Supplier Info Successfully',
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
  $validation->required('employeeno');
  $validation->required('employeeincometax');
  $validation->required('employeegrosswage');
  $validation->required('employeeni');
  $validation->required('employeepension');
  $validation->required('employeeotherbenefit');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entryperiod'),
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Submitted Employee Info Successfully',
  });
}

1;
