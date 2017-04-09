use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;

plugin 'Pear::LocalLoop::Plugin::Validators';

my $validator = app->validator;

my $validation = $validator->validation;

my $valid_email = 'test@example.com';
my $invalid_email = 'test.example.com';
my $valid_postcode = 'WC1H 9EB';
my $invalid_postcode = 'AB1 2CD';

$validation->input({
  valid_email => $valid_email,
  invalid_email => $invalid_email,
  valid_postcode => $valid_postcode,
  invalid_postcode => $invalid_postcode,
});

$validation->required('valid_email')->email;
$validation->required('invalid_email')->email;
$validation->required('valid_postcode')->postcode;
$validation->required('invalid_postcode')->postcode;

ok $validation->has_error, 'Have Errors';
is_deeply $validation->failed, [ 'invalid_email', 'invalid_postcode' ], 'Correct Errors';

done_testing;
