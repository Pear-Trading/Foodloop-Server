package Pear::LocalLoop::Controller::Api::Api;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub post_edit {
  my $self = shift;

  my $json = $self->req->json;

  my $account = $self->get_account_by_username( $json->{username} );

  unless ( defined $account ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username not recognised, has your token expired?',
    });
# PLUG SECURITY HOLE
  } elsif ( $account->{keyused} ne 't' ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token has not been used yet!',
    });
  }
  my $insert = $self->db->prepare("UPDATE accounts SET fullname = ?, postcode = ?, age = ?, gender = ?, WHERE username = ?");
  $insert->execute(
    @{$json}{ qw/ fullname postcode age gender / }, $account->{username},
  );

  $self->render( json => { success => Mojo::JSON->true } );
}


sub post_fetchuser {
  my $self = shift;

  my $json = $self->req->json;

  my $account = $self->get_account_by_username( $json->{username} );

  unless ( defined $account ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Username not recognised, has your token expired?',
    });
# PLUG SECURITY HOLE
  } elsif ( $account->{keyused} ne 't' ) {
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Token has not been used yet!',
    });
  }

# Add stuff to send back to user below here!
  $self->render( json => { 
  success => Mojo::JSON->true,
  });
}

1;
