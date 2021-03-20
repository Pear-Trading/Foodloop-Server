package Pear::LocalLoop::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub index {
## use critic
    my $c = shift;

    #  if ( $c->is_user_authenticated ) {
    #   $c->redirect_to('/home');
    #  }
    
    return 1;
}

sub under {
    my $c = shift;

    if ( $c->is_user_authenticated ) {
        return 1;
    }
    $c->redirect_to('/');
    return;
}

sub auth_login {
    my $c = shift;

    if ( $c->authenticate( $c->param('email'), $c->param('password') ) ) {
        $c->redirect_to('/home');
    }
    else {
        $c->redirect_to('/');
    }
    
    return 1;
}

sub auth_logout {
    my $c = shift;

    $c->logout;
    $c->redirect_to('/');
    
    return 1;
}

sub home {
    my $c = shift;
    
    return 1;
}

1;
