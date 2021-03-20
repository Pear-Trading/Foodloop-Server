package Pear::LocalLoop::Import::Role::Schema;
use strict;
use warnings;
use Moo::Role;

has schema => (
    is       => 'ro',
    required => 1,
);

1;
