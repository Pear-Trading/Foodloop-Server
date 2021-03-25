package Pear::LocalLoop::Plugin::Minion::Job::entity_postcode_lookup;
use Mojo::Base 'Pear::LocalLoop::Plugin::Minion::Job';

sub run {
    my ( $self, $entity_id ) = @_;

    my $entity_rs = $self->app->schema->resultset('Entity');
    $entity_rs = $entity_rs->search( { id => $entity_id } ) if $entity_id;

    while ( my $entity = $entity_rs->next ) {
        my $obj = $entity->type_object;
        next unless $obj;

        my $postcode_obj = Geo::UK::Postcode::Regex->parse( $obj->postcode );

        unless ( defined $postcode_obj && $postcode_obj->{non_geographical} ) {
            my $pc_result = $self->app->schema->resultset('GbPostcode')->find(
                {
                    incode  => $postcode_obj->{incode},
                    outcode => $postcode_obj->{outcode},
                }
            );
            if ( defined $pc_result ) {
                $entity->update_or_create_related(
                    'postcode',
                    {
                        gb_postcode => $pc_result,
                    }
                );
            }
        }
    }

    return 1;
}

1;
