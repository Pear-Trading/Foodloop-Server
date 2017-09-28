package Pear::LocalLoop::Controller::Api::V1::Supplier::Location;
use Mojo::Base 'Mojolicious::Controller';

has validation_data => sub {
  my $children_errors = {
    latitude => {
      validation => [
        { required => {} },
        { number => { error_prefix => 'not_number' } },
        { in_range => { args => [ -90, 90 ], error_prefix => 'outside_range' } },
      ],
    },
    longitude => {
      validation => [
        { required => {} },
        { number => { error_prefix => 'not_number' } },
        { in_range => { args => [ -180, 180 ], error_prefix => 'outside_range' } },
      ],
    },
  };

  return {
    index => {
      north_east => {
        validation => [
          { required => {} },
          { is_object => { error_prefix => 'not_object' } },
        ],
        children => $children_errors,
      },
      south_west => {
        validation => [
          { required => {} },
          { is_object => { error_prefix => 'not_object' } },
        ],
        children => $children_errors,
      },
    }
  }
};

sub index {
  my $c = shift;

  return if $c->validation_error('index');

  my $json = $c->stash->{api_json};

  # Extra custom error, because its funny
  if ( $json->{north_east}->{latitude} < $json->{south_west}->{latitude} ) {
    return $c->render(
      json => {
        success => Mojo::JSON->false,
        errors => [ 'upside_down' ],
      },
      status => 400,
    );
  }

  my $entity = $c->stash->{api_user}->entity;
  my $entity_type_object = $entity->type_object;

  # need: organisations only, with name, latitude, and longitude
  my $org_rs = $entity->purchases->search_related('seller',
    {
      'seller.type' => 'organisation',
      'organisation.latitude' => { -between => [
        $json->{south_west}->{latitude},
        $json->{north_east}->{latitude},
      ] },
      'organisation.longitude' => { -between => [
        $json->{south_west}->{longitude},
        $json->{north_east}->{longitude},
      ] },
    },
    {
      join => [ qw/ organisation / ],
      columns => [
        'organisation.name',
        'organisation.latitude',
        'organisation.longitude',
      ],
      group_by => [ qw/ organisation.id / ],
    },
  );

  $org_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

  my $suppliers = [ map { 
    {
      latitude => $_->{organisation}->{latitude} * 1,
      longitude => $_->{organisation}->{longitude} * 1,
      name => $_->{organisation}->{name},
    }
  } $org_rs->all ];

  $c->render(
    json => {
      success => Mojo::JSON->true,
      suppliers => $suppliers,
      self => {
        latitude => $entity_type_object->latitude,
        longitude => $entity_type_object->longitude,
      }
    },
  );
}

1;
