package Pear::LocalLoop::Schema::ResultSet::Organisation;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub entity { return shift->search_related( 'entity', @_ ) }

1;
