package Pear::LocalLoop::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::JSON;


#FIXME placeholders
#Because of "before_dispatch" this will never be accessed unless the user is not logged in.
sub get_login {
  my $self = shift;
  return $self->render( success => Mojo::JSON->true, text => 'This will be the login page.', status => 200 );
}

#TODO set session cookie and add it to the database.
#FIXME This suffers from replay attacks, consider a challenge response. Would TLS solve this, most likely.
#SessionToken
#Because of "before_dispatch" this will never be accessed unless the user is not logged in.
sub post_login {
  my $self = shift;

  my $json = $self->req->json;
  $self->app->log->debug( "\n\nStart of login");
  $self->app->log->debug( "JSON: " . Dumper $json );

  if ( ! defined $json ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No json sent.',
    },
    status => 400,); #Malformed request   
  }

  my $email = $json->{email};
  if ( ! defined $email ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No email sent.',
    },
    status => 400,); #Malformed request   
  }
  elsif ( ! $self->valid_email($email) ) {  
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'email is invalid.',
    },
    status => 400,); #Malformed request
  }

  my $password = $json->{password};
  if ( ! defined $password ){
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'No password sent.',
    },
    status => 400,); #Malformed request   
  }


  #FIXME There is a timing attack here determining if an email exists or not.
  if ($self->does_email_exist($email) && $self->check_password_email($email, $password)) {
    #Match.
    $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);

    my $userId = $self->get_userid_foreign_key($email);

    #Generates and stores
    my $hash = $self->generate_session($userId);

    $self->app->log->debug('session dump:' . Dumper ($hash));

    return $self->render( json => { 
      success => Mojo::JSON->true,
      $self->config->{sessionTokenJsonName} => $hash->{$self->config->{sessionTokenJsonName}},
      $self->config->{sessionExpiresJsonName} => $hash->{$self->config->{sessionExpiresJsonName}},
    });
  }
  else{
    #Mismatch
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'Email or password is invalid.',
    },
    status => 401,); #Unauthorized request 
  }
}

sub post_logout {
  my $self = shift;

  my $json = $self->req->json;
  $self->app->log->debug( "\n\nStart of logout");
  $self->app->log->debug( "JSON: " . Dumper $json );

  #If the session token exists.
  if ($self->expire_current_session()) {
    $self->app->log->debug('Path Success: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->true,
      message => 'you were successfully logged out.',
    }); 
  }
  #Due to the "before_dispatch" hook, this most likely will not be called. i.e. race conditions.
  #FIXME untested.
  #An invalid token was presented, most likely because it has expired.
  else {
    $self->app->log->debug('Path Error: file:' . __FILE__ . ', line: ' . __LINE__);
    return $self->render( json => {
      success => Mojo::JSON->false,
      message => 'the session has expired or did not exist in the first place.',
    },
    status => 401,); #Unauthorized request
  }

}



1;
