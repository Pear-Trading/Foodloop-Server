use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;

#test email errors
$t->post_ok('/api/feedback' => json => {
    email => '',
    feedbacktext => 'banana',
    app_name => 'Foodloop Web',
    package_name => 'Foodloop Web',
    version_code => 'dev',
    version_number => 'dev',
  })
  ->status_is(400)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Email is required or not registered/);

$t->post_ok('/api/feedback' => json => {
    feedbacktext => 'banana',
    app_name => 'Foodloop Web',
    package_name => 'Foodloop Web',
    version_code => 'dev',
    version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Email is required or not registered/);

$t->post_ok('/api/feedback' => json => {
  email => 'banana',
  feedbacktext => 'banana',
  app_name => 'Foodloop Web',
  package_name => 'Foodloop Web',
  version_code => 'dev',
  version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Email is required or not registered/);

$t->post_ok('/api/feedback' => json => {
  email => 'test21318432148@example.com',
  feedbacktext => 'banana',
  app_name => 'Foodloop Web',
  package_name => 'Foodloop Web',
  version_code => 'dev',
  version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Email is required or not registered/);

# Test for missing feedback
$t->post_ok('/api/feedback' => json => {
  email => 'test1@example.com',
  app_name => 'Foodloop Web',
  package_name => 'Foodloop Web',
  version_code => 'dev',
  version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Feedback is required/);

$t->post_ok('/api/feedback' => json => {
  email => 'test1@example.com',
  feedbacktext => '',
  app_name => 'Foodloop Web',
  package_name => 'Foodloop Web',
  version_code => 'dev',
  version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Feedback is required/);

# Test for missing extra details
$t->post_ok('/api/feedback' => json => {
  email => 'test1@example.com',
  feedbacktext => 'banana',
  package_name => 'Foodloop Web',
  version_code => 'dev',
  version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/App Name is required/);

$t->post_ok('/api/feedback' => json => {
  email => 'test1@example.com',
  feedbacktext => 'banana',
  app_name => 'Foodloop Web',
  version_code => 'dev',
  version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Package Name is required/);

$t->post_ok('/api/feedback' => json => {
  email => 'test1@example.com',
  feedbacktext => 'banana',
  app_name => 'Foodloop Web',
  package_name => 'Foodloop Web',
  version_number => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Version Code is required/);

$t->post_ok('/api/feedback' => json => {
  email => 'test1@example.com',
  feedbacktext => 'banana',
  app_name => 'Foodloop Web',
  package_name => 'Foodloop Web',
  version_code => 'dev',
  })
  ->status_is(400)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->false)
  ->json_like('/message', qr/Version Number is required/);

# Valid Feedback
$t->post_ok('/api/feedback' => json => {
  email => 'test1@example.com',
  feedbacktext => 'banana',
  app_name => 'Foodloop Web',
  package_name => 'Foodloop Web',
  version_code => 'dev',
  version_number => 'dev',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true);

done_testing;
