package Pear::LocalLoop::Schema::ResultSet::Organisation;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

## no critic (Subroutines::RequireArgUnpacking)
sub entity { return shift->search_related( 'entity', @_ ) }
## use critic

1;
