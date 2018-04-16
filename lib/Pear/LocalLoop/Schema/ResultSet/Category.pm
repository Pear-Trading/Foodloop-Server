package Pear::LocalLoop::Schema::ResultSet::Category;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub as_hash {
  my ( $self ) = @_;

  my %category_list = (
    (
      map {
        $_->id => $_->name,
      } $self->all
    ),
    0 => 'Uncategorised',
  );
  return \%category_list;
}

1;
