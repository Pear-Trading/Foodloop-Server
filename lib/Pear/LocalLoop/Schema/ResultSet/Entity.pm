package Pear::LocalLoop::Schema::ResultSet::Entity;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub sales { shift->search_related('sales', @_) }

1;
