use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;

my $session_key = $framework->login({
  email => 'org@example.com',
  password => 'abc123',
});

## Payroll Data Submission

#No JSON sent
$t->post_ok('/api/v1/organisation/payroll/add')
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/JSON is missing/i);

#Empty JSON
$t->post_ok('/api/v1/organisation/payroll/add' => json => {})
  ->json_is('/success', Mojo::JSON->false);

# no session key
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(401)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Invalid Session/);

# No entry_period
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/No entry period/);

# No employee_amount
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/No employee amount/);

# No local_employee_amount
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/local employee amount/);

# No gross_payroll
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/No gross payroll/);

# No payroll_income_tax
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/No total income tax/);

# No payroll_employee_ni
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/No total employee NI/);

# No payroll_employer_ni
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/total employer NI/);

# No payroll_total_pension
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/No total total pension/);

# No payroll_other_benefit
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/No total other benefits total/);

# Valid payroll submission
$t->post_ok('/api/v1/organisation/payroll/add' => json => {
    session_key => $session_key,
    entry_period => '2017-12',
    employee_amount => '10',
    local_employee_amount => '10',
    gross_payroll => '10',
    payroll_income_tax => '10',
    payroll_employee_ni => '10',
    payroll_employer_ni => '10',
    payroll_total_pension => '10',
    payroll_other_benefit => '10',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

## Supplier Form submission

#TODO make the test!

## Employee Form submission

#TODO make the test!

$framework->logout( $session_key );

done_testing;
