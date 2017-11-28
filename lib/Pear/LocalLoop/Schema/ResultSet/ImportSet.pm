package Pear::LocalLoop::Schema::ResultSet::ImportSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub get_values {
  my $self = shift;
  my $id = shift;
  my $include_ignored = shift;
  my $include_imported = shift;

  return $self->find($id)->search_related(
    'values',
    {
      ( $include_ignored ? () : ( ignore_value => 0 ) ),
      ( $include_imported ? () : ( transaction_id =>  undef ) ),
    },
    {
      order_by => { '-asc' => 'id' },
    },
  );
}

sub _unordered_get_values {
  my $self = shift;
  my $id = shift;
  my $include_ignored = shift;
  my $include_imported = shift;

  return $self->find($id)->search_related(
    'values',
    {
      ( $include_ignored ? () : ( ignore_value => 0 ) ),
      ( $include_imported ? () : ( transaction_id =>  undef ) ),
    },
  );
}

sub get_users {
  my $self = shift;

  return $self->_unordered_get_values(@_)->search({},
    {
      group_by => 'user_name',
      columns => [ qw/ user_name / ],
    },
  );
}

sub get_orgs {
  my $self = shift;
  
  return $self->_unordered_get_values(@_)->search({},
    {
      group_by => 'org_name',
      columns => [ qw/ org_name / ],
    },
  );
}

sub get_lookups {
  my $self = shift;
  my $id = shift;

  my $lookup_rs = $self->find($id)->search_related(
    'lookups',
    undef,
    {
      prefetch => { entity => [ qw/ organisation customer / ] },
      order_by => { '-asc' => 'me.id' },
    },
  );
  my $lookup_map = {
    map {
      $_->name => {
        entity_id => $_->entity->id,
        name => $_->entity->name,
      },
    } $lookup_rs->all
  };
  return $lookup_map;
}

1;
