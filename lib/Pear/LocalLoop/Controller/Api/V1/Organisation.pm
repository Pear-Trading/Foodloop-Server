package Pear::LocalLoop::Controller::Api::V1::Organisation;
use Mojo::Base 'Mojolicious::Controller';

sub auth {
    my $c = shift;

    return 1 if $c->stash->{api_user}->type eq 'organisation';

    $c->render(
        json => {
            success => Mojo::JSON->false,
            message => 'Not an Organisation',
            error   => 'user_not_org',
        },
        status => 403,
    );

    return 0;
}

1;
