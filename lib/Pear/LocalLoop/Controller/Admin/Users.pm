package Pear::LocalLoop::Controller::Admin::Users;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;
use Data::Dumper;

has user_result_set => sub {
    my $c = shift;
    return $c->schema->resultset('User');
};

has customer_result_set => sub {
    my $c = shift;
    return $c->schema->resultset('Customer');
};

has organisation_result_set => sub {
    my $c = shift;
    return $c->schema->resultset('Organisation');
};

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub index {
## use critic
    my $c = shift;

    my $user_rs = $c->user_result_set->search(
        undef,
        {
            prefech  => { entity => [qw/ customer organisation /] },
            page     => $c->param('page') || 1,
            rows     => 10,
            order_by => { -asc => 'email' },
        }
    );
    $c->stash( user_rs => $user_rs );

    return 1;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub read {
## use critic
    my $c = shift;

    my $id = $c->param('id');

    if ( my $user = $c->user_result_set->find($id) ) {
        my $transactions = $user->entity->purchases->search(
            undef,
            {
                page     => $c->param('page') || 1,
                rows     => 10,
                order_by => { -desc => 'submitted_at' },
            },
        );
        $c->stash(
            user         => $user,
            transactions => $transactions,
        );
    }
    else {
        $c->flash( error => 'No User found' );
        $c->redirect_to('/admin/users');
    }

    return 1;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub update {
## use critic
    my ( $c, $error ) = @_;

    my $id = $c->param('id');

    my $user;

    unless ( $user = $c->user_result_set->find($id) ) {
        $c->flash( error => 'No User found' );
        return $c->redirect_to( '/admin/users/' . $id );
    }

    my $validation = $c->validation;

    my $not_myself_user_rs = $c->user_result_set->search(
        {
            id => { "!=" => $user->id },
        }
    );
    $validation->required('email')
      ->email->not_in_resultset( 'email', $not_myself_user_rs );
    $validation->required('postcode')->postcode;
    $validation->optional('new_password');

    if ( $user->type eq 'customer' ) {
        $validation->required('display_name');
        $validation->required('full_name');
    }
    elsif ( $user->type eq 'organisation' ) {
        $validation->required('name');
        $validation->required('street_name');
        $validation->required('town');
        $validation->optional('sector');
    }

    if ( $validation->has_error ) {
        $c->flash( error => 'The validation has failed' );
        return $c->redirect_to( '/admin/users/' . $id );
    }

    my $location =
      $c->get_location_from_postcode( $validation->param('postcode'),
        $user->type, );

    if ( $user->type eq 'customer' ) {

        try {
            $c->schema->txn_do(
                sub {
                    $user->entity->customer->update(
                        {
                            full_name    => $validation->param('full_name'),
                            display_name => $validation->param('display_name'),
                            postcode     => $validation->param('postcode'),
                            (
                                defined $location
                                ? (%$location)
                                : ( latitude => undef, longitude => undef )
                            ),
                        }
                    );
                    $user->update(
                        {
                            email => $validation->param('email'),
                            (
                                defined $validation->param('new_password')
                                ? ( password =>
                                      $validation->param('new_password') )
                                : ()
                            ),
                        }
                    );
                }
            );
        }
        finally {
            if ($error) {
                $c->flash( error => 'Something went wrong Updating the User' );
                $c->app->log->warn( Dumper $error );
            }
            else {
                $c->flash( success => 'Updated User' );
            }
        }
    }
    elsif ( $user->type eq 'organisation' ) {

        try {
            $c->schema->txn_do(
                sub {
                    $user->entity->organisation->update(
                        {
                            name        => $validation->param('name'),
                            street_name => $validation->param('street_name'),
                            town        => $validation->param('town'),
                            sector      => $validation->param('sector'),
                            postcode    => $validation->param('postcode'),
                            (
                                defined $location
                                ? (%$location)
                                : ( latitude => undef, longitude => undef )
                            ),
                        }
                    );
                    $user->update(
                        {
                            email => $validation->param('email'),
                            (
                                defined $validation->param('new_password')
                                ? ( password =>
                                      $validation->param('new_password') )
                                : ()
                            ),
                        }
                    );
                }
            );
        }
        finally {
            if ($error) {
                $c->flash( error => 'Something went wrong Updating the User' );
                $c->app->log->warn( Dumper $error );
            }
            else {
                $c->flash( success => 'Updated User' );
            }
        }
    }

    $c->redirect_to( '/admin/users/' . $id );

    return 1;
}

1;
