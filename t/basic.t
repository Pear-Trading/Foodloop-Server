use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use FindBin;

BEGIN {
  $ENV{MOJO_MODE} = 'testing';
  $ENV{MOJO_LOG_LEVEL} = 'debug';
}

my $t = Test::Mojo->new("Pear::LocalLoop");
$t->get_ok('/')->status_is(200);

done_testing();
