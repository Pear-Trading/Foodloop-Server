use Test::More;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/../foodloopserver.pl";

my $t = Test::Mojo->new;
$t->get_ok('/login')->status_is(200)->content_like(qr/login page/);

done_testing();
