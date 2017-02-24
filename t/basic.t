use Test::More;
use Test::Mojo;

use FindBin;
my $t = Test::Mojo->new("Pear::LocalLoop");
$t->get_ok('/login')->status_is(200)->content_like(qr/login page/);

done_testing();
