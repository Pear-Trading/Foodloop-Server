package Pear::LocalLoop::Schema::ResultSet::ImportSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub get_values {
  my $self = shift;
  my $id = shift;

  return $self->find($id)->search_related(
    'values',
    undef,
    {
      order_by => { -asc => 'id' },
    },
  );
}

sub get_users {
  my $self = shift;
  my $id = shift;

  return $self->get_values($id)->search({},
    {
      group_by => 'user_name',
    },
  );
}

sub get_orgs {
  my $self = shift;
  my $id = shift;
  
  return $self->get_values($id)->search({},
    {
      group_by => 'org_name',
    },
  );
}

1;
