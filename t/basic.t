use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Test::Pear::LocalLoop;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
$t->get_ok('/')->status_is(200);

done_testing();
