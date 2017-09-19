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
      required => { message => 'No total income tax sent.', status => 400 },
    },
    payroll_employee_ni => {
      required => { message => 'No total employee NI sent.', status => 400 },
    },
    payroll_employer_ni => {
      required => { message => 'No total employer NI sent.', status => 400 },
    },
    payroll_total_pension => {
      required => { message => 'No total total pension sent.', status => 400 },
    },
    payroll_other_benefit => {
      required => { message => 'No total other benefits total sent.', status => 400 },
    },
    supplier_business_name => {
      required => { message => 'No supplier business name sent.', status => 400 },
    },
    postcode => {
      required => { message => 'No postcode sent.', status => 400 },
      postcode => { message => 'postcode must be valid', status => 400 },
    },
    monthly_spend => {
      required => { message => 'No monthly spend sent.', status => 400 },
    },
    employee_no => {
      required => { message => 'No employee no sent.', status => 400 },
    },
    employee_income_tax => {
      required => { message => 'No employee income tax sent.', status => 400 },
    },
    employee_gross_wage => {
      required => { message => 'No employee gross wage sent.', status => 400 },
    },
    employee_ni => {
      required => { message => 'No employee ni sent.', status => 400 },
    },
    employee_pension => {
      required => { message => 'No employee pension sent.', status => 400 },
    },
    employee_other_benefit => {
      required => { message => 'No employee other benefits sent.', status => 400 },
    },
  };
};

sub post_payroll_read {
  my $c = shift;

  my $user = $c->stash->{api_user};

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );
  $validation->optional('page')->number;

  return $c->api_validation_error if $validation->has_error;

  my $payrolls = $user->entity->organisation->payroll->search(
    undef, {
      page => $validation->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'submitted_at' },
    },
  );

# purchase_time needs timezone attached to it
  my @payroll_list = (
    map {{
      entry_period          => $_->entry_period,
      employee_amount       => $_->employee_amount,
      local_employee_amount => $_->local_employee_amount,
      gross_payroll         => $_->gross_payroll / 100000,
      payroll_income_tax    => $_->payroll_income_tax / 100000,
      payroll_employee_ni   => $_->payroll_employee_ni / 100000,
      payroll_employer_ni   => $_->payroll_employer_ni / 100000,
      payroll_total_pension => $_->payroll_total_pension / 100000,
      payroll_other_benefit => $_->payroll_other_benefit / 100000,
    }} $payrolls->all
  );

  return $c->render( json => {
    success => Mojo::JSON->true,
    payrolls => \@payroll_list,
    page_no => $payrolls->pager->total_entries,
  });
}

sub post_payroll_add {
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

  my $entry_period = $c->parse_iso_month($validation->param('entry_period'));
  my $employee_amount = $validation->param('employee_amount');
  my $local_employee_amount = $validation->param('local_employee_amount');
  my $gross_payroll = $validation->param('gross_payroll');
  my $payroll_income_tax = $validation->param('payroll_income_tax');
  my $payroll_employee_ni = $validation->param('payroll_employee_ni');
  my $payroll_employer_ni = $validation->param('payroll_employer_ni');
  my $payroll_total_pension = $validation->param('payroll_total_pension');
  my $payroll_other_benefit = $validation->param('payroll_other_benefit');

  $c->schema->txn_do( sub {
    $user->entity->organisation->payroll->create({
      entry_period          => $entry_period,
      employee_amount       => $employee_amount,
      local_employee_amount => $local_employee_amount,
      gross_payroll         => $gross_payroll * 100000,
      payroll_income_tax    => $payroll_income_tax * 100000,
      payroll_employee_ni   => $payroll_employee_ni * 100000,
      payroll_employer_ni   => $payroll_employer_ni * 100000,
      payroll_total_pension => $payroll_total_pension * 100000,
      payroll_other_benefit => $payroll_other_benefit * 100000,
    });
  });

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Submitted Payroll Info Successfully',
  });
}

sub post_supplier_read {

}

sub post_supplier_add {
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

sub post_employee_read {

}

sub post_employee_add {
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
