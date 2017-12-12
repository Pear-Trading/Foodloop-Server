package Pear::LocalLoop::Controller::Api::V1::Customer;
use Mojo::Base 'Mojolicious::Controller';

sub auth {
  my $c = shift;

  return 1 if $c->stash->{api_user}->type eq 'customer';

  $c->render(
    json => {
      success => Mojo::JSON->false,
      message => 'Not an Customer',
      error   => 'user_not_cust',
    },
    status => 403,
  );

  return 0;
}

1;
