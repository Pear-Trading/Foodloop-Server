package Pear::LocalLoop::Controller::Api::V1::User::Points;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/true false/;

sub index {
    my $c = shift;

    my $validation = $c->validation;
    $validation->input( $c->stash->{api_json} );

    # Placeholder data
    my $snippets_placeholder = {
        points_total => 1,
        point_last   => 1,
        trans_count  => 1,
        avg_multi    => 1,
    };

    my $widget_line_placeholder = { labels => [], data => [] };

    my $widget_progress_placeholder = {
        this_week => 1,
        last_week => 1,
        max       => 1,
        sum       => 1,
        count     => 1,
    };

    return $c->render(
        json => {
            success         => Mojo::JSON->true,
            snippets        => $snippets_placeholder,
            widget_line     => $widget_line_placeholder,
            widget_progress => $widget_progress_placeholder,
        }
    );
}

1;
