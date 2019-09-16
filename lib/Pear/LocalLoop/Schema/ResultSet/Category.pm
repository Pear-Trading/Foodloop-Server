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

sub as_hash_name_icon {
  my ( $self ) = @_;

  my %category_list = (
    (
      map {
        $_->name => $_->line_icon,
      } $self->all
    ),
    0 => 'Uncategorised',
  );
  return \%category_list;
}

1;
