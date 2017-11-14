package Pear::LocalLoop::Schema::ResultSet::ImportSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub get_values {
  my $self = shift;
  my $id = shift;
  my $include_ignored = shift;

  return $self->find($id)->search_related(
    'values',
    ( $include_ignored ? {} : { ignore_value => 0 } ),
    {
      order_by => { '-asc' => 'id' },
    },
  );
}

sub get_users {
  my $self = shift;
  my $id = shift;
  my $include_ignored = shift;

  return $self->get_values($id, $include_ignored)->search({},
    {
      group_by => 'user_name',
    },
  );
}

sub get_orgs {
  my $self = shift;
  my $id = shift;
  my $include_ignored = shift;
  
  return $self->get_values($id, $include_ignored)->search({},
    {
      group_by => 'org_name',
    },
  );
}

sub get_lookups {
  my $self = shift;
  my $id = shift;

  return $self->find($id)->search_related(
    'lookups',
    undef,
    {
      order_by => { '-asc' => 'id' },
    },
  );
}

1;
