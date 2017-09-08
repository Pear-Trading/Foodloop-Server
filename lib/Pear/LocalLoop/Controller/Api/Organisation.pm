package Pear::LocalLoop::Controller::Api::Organisation;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

has error_messages => sub {
  return {
    entry_period => {
      required => { message => 'No entry period sent.', status => 400 },
    },
    employee_amount => {
      required => { message => 'No employee amount sent.', status => 400 },
    },
    local_employee_amount => {
      required => { message => 'No local employee amount sent.', status => 400 },
    },
    gross_payroll => {
      required => { message => 'No gross payroll sent.', status => 400 },
    },
    payroll_income_tax => {
      required => { message => 'no payroll income tax sent.', status => 400 },
    },
    payroll_employee_ni => {
      required => { message => 'no payroll employee ni sent.', status => 400 },
    },
    payroll_employer_ni => {
      required => { message => 'no payroll employer ni sent.', status => 400 },
    },
    payroll_total_pension => {
      required => { message => 'no payroll total pension sent.', status => 400 },
    },
    payroll_other_benefit => {
      required => { message => 'no payroll other benefit sent.', status => 400 },
    },
    supplier_business_name => {
      required => { message => 'no supplier business name sent.', status => 400 },
    },
    postcode => {
      required => { message => 'no postcode sent.', status => 400 },
      postcode => { message => 'postcode must be valid', status => 400 },
    },
    monthly_spend => {
      required => { message => 'no monthly spend sent.', status => 400 },
    },
    employee_no => {
      required => { message => 'no employee no sent.', status => 400 },
    },
    employee_income_tax => {
      required => { message => 'no employee income tax sent.', status => 400 },
    },
    employee_gross_wage => {
      required => { message => 'no employee gross wage sent.', status => 400 },
    },
    employee_ni => {
      required => { message => 'no employee ni sent.', status => 400 },
    },
    employee_pension => {
      required => { message => 'no employee pension sent.', status => 400 },
    },
    employee_other_benefit => {
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

  $validation->required('entry_period');
  $validation->required('employee_amount');
  $validation->required('local_employee_amount');
  $validation->required('gross_payroll');
  $validation->required('payroll_income_tax');
  $validation->required('payroll_employee_ni');
  $validation->required('payroll_employer_ni');
  $validation->required('payroll_total_pension');
  $validation->required('payroll_other_benefit');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entry_period'),
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

  $validation->required('entry_period');
  $validation->required('postcode')->postcode;
  $validation->required('supplier_business_name');
  $validation->required('monthly_spend');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entry_period'),
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

  $validation->required('entry_period');
  $validation->required('employee_no');
  $validation->required('employee_income_tax');
  $validation->required('employee_gross_wage');
  $validation->required('employee_ni');
  $validation->required('employee_pension');
  $validation->required('employee_other_benefit');

  return $c->api_validation_error if $validation->has_error;

  $c->schema->txn_do( sub {
    $user->entity->organisation->update({
      entry_period        => $validation->param('entry_period'),
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Submitted Employee Info Successfully',
  });
}

1;
