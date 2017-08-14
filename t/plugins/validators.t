use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;

plugin 'Pear::LocalLoop::Plugin::Datetime';
plugin 'Pear::LocalLoop::Plugin::Validators';

my $validator = app->validator;

my $validation = $validator->validation;

my $valid_email = 'test@example.com';
my $invalid_email = 'test.example.com';
my $valid_postcode = 'WC1H 9EB';
my $invalid_postcode = 'AB1 2CD';
my $not_a_postcode = 'a';
my $not_a_whole_postcode = 'LA1';
my $valid_purchase_time = '2017-08-14T11:29:07.965+01:00';
my $invalid_purchase_time = '2017081411:29:07';

$validation->input({
  valid_email => $valid_email,
  invalid_email => $invalid_email,
  valid_postcode => $valid_postcode,
  invalid_postcode => $invalid_postcode,
  not_a_postcode => $not_a_postcode,
  not_a_whole_postcode => $not_a_whole_postcode,
  valid_purchase_time => $valid_purchase_time,
  invalid_purchase_time => $invalid_purchase_time,
});

$validation->required('valid_email')->email;
$validation->required('invalid_email')->email;
$validation->required('valid_postcode')->postcode;
$validation->required('invalid_postcode')->postcode;
$validation->required('not_a_postcode')->postcode;
$validation->required('not_a_whole_postcode')->postcode;
$validation->required('valid_purchase_time')->is_full_iso_datetime;
$validation->required('invalid_purchase_time')->is_full_iso_datetime;

ok $validation->has_error, 'Have Errors';
is_deeply $validation->failed, [ qw/ invalid_email invalid_postcode invalid_purchase_time not_a_postcode not_a_whole_postcode / ], 'Correct Errors';

done_testing;
