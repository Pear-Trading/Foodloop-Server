package Pear::LocalLoop::Controller::Api::Topic;
use Mojo::Base 'Mojolicious::Controller';
use LWP::UserAgent;
use JSON;
use JSON::Parse 'parse_json';
use Mojo::JWT;
use Mojo::File;
use Carp;

has error_messages => sub {
    return {
        topic => {
            required => { message => 'Topic is required', status => 400 },
            not_in_resultset => { message => 'Topic already exists', status => 400 },
        }
    };
};

sub create {
    my $c = shift;

    my $user = $c->stash->{api_user};

    my $validation = $c->validation;
    $validation->input( $c->stash->{api_json} );

    my $topic_rs = $c->schema->resultset('Topic');
    my $user_rs  = $c->schema->resultset('User');
    
    $validation->required('topic')->not_in_resultset( 'topic', $topic_rs );
    # TODO: validate that requester is an org user
    
 		my $organisation = $user->entity->organisation;
    
    return $c->api_validation_error if $validation->has_error;
    
    my $topic = $validation->param('topic');

    $organisation->create_related(
        'topics',
        {
            name => $topic,
        }
    );

    return $c->render(
        json => {
            success => Mojo::JSON->true,
            message => 'Topic created successfully!',
        }
    );
}

sub get_all {
    my $c = shift;

    my $topic_rs = $c->schema->resultset('Topic');

    my @topics = (
        map {
            {
                id                  => $_->id,
                name                => $_->name,
                numberOfSubscribers =>
                  $_->search_related( 'device_subscriptions',
                    { 'topic_id' => $_->id } )->count,
            }
        } $topic_rs->all
    );

    return $c->render(
        json => {
            success => Mojo::JSON->true,
            topics  => \@topics,
        }
    );
}
1;
