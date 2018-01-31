package Pear::LocalLoop::Controller::Api::V1::User::Medals;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/true false/;

sub index {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $global = {
    group_name => {
      threshold => {
        awarded => true,
        awarded_at => '2017-01-02T01:00:00Z',
        threshold => 1,
        points => 1,
      },
      total => 1,
    },
  };
  my $organisation = {
    org_id => {
      group_name => {
        threshold => {
          awarded => true,
          awarded_at => '2017-01-02T01:00:00Z',
          threshold => 1,
          points => 1,
          multiplier => 1,
        },
        total => 1,
      },
      name => 'Placeholder',
    },
  };

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      global => $global,
      organisation => $organisation,
    }
  );
}

1;
