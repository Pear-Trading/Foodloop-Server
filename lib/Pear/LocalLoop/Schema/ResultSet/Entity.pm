package Pear::LocalLoop::Schema::ResultSet::Entity;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub sales { shift->search_related( 'sales', @_ ) }

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
