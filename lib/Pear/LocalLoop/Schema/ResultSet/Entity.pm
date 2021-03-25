package Pear::LocalLoop::Schema::ResultSet::Entity;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

## no critic (Subroutines::RequireArgUnpacking)
sub sales { return shift->search_related( 'sales', @_ ) }
## use critic

sub create_org {
    my ( $self, $org ) = @_;

    return $self->create(
        {
            organisation => $org,
            type         => 'organisation',
        }
    );
}

1;
