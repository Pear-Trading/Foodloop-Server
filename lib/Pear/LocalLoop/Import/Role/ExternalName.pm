package Pear::LocalLoop::Import::Role::ExternalName;
use strict;
use warnings;
use Moo::Role;

requires qw/
  external_name
  schema
  /;

has external_result => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        return $self->schema->resultset('ExternalReference')
          ->find_or_create( { name => $self->external_name } );
    }
);

1;
