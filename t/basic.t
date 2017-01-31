use Test::More;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/../foodloopserver.pl";

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_like(qr/server/);

done_testing();