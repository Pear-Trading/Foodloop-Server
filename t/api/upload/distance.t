use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use GIS::Distance;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../../etc",
);
$framework->install_fixtures('full');

my $t = $framework->framework;
my $schema = $t->app->schema;

my $session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

my $test_purchase_time = "2017-08-14T11:29:07.965+01:00";

$t->post_ok('/api/upload' => json => {
    transaction_value => 10,
    transaction_type => 1,
    purchase_time => $test_purchase_time,
    organisation_id => 1,
    session_key => $session_key,
  })
  ->status_is(200)
  ->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true)
  ->json_like('/message', qr/Upload Successful/);

is $schema->resultset('Transaction')->count, 1, "1 transaction";

my $transaction = $schema->resultset('Transaction')->first;

my $gis = GIS::Distance->new();
my $expected_distance = int( $gis->distance(
  # Buyer
  54.04, -2.8,
  # Seller
  54.04725, -2.79611,
)->meters );

is $transaction->distance, $expected_distance, 'Transaction Distance Correct';

done_testing;
