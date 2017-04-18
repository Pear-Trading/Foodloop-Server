package Pear::LocalLoop;

use Mojo::Base 'Mojolicious';
use Data::UUID;
use Mojo::JSON;
use Scalar::Util qw(looks_like_number);
use Pear::LocalLoop::Schema;
use DateTime;

has schema => sub {
  my $c = shift;
  return Pear::LocalLoop::Schema->connect(
    $c->app->config->{dsn},
    $c->app->config->{user},
    $c->app->config->{pass},
  );
};

sub startup {
  my $self = shift;

  $self->plugin('Config', {
    default => {
      sessionTimeSeconds => 60 * 60 * 24 * 7,
      sessionTokenJsonName => 'session_key',
      sessionExpiresJsonName => 'sessionExpires',
    },
  });
  my $config = $self->config;

  $self->plugin('Pear::LocalLoop::Plugin::Validators');

  $self->plugin('Authentication' => {
    'load_user' => sub {
      my ( $c, $user_id ) = @_;
      return $c->schema->resultset('User')->find($user_id);
    },
    'validate_user' => sub {
      my ( $c, $email, $password, $args) = @_;
      my $user = $c->schema->resultset('User')->find({email => $email});
      if ( defined $user ) {
        if ( $user->check_password( $password ) ) {
            return $user->userid;
        }
      }
      return undef;
    },
  });

  # shortcut for use in template
  $self->helper( db => sub { $self->app->schema->storage->dbh });
  $self->helper( schema => sub { $self->app->schema });


  my $r = $self->routes;
  $r->get('/')->to('root#index');
  $r->post('/')->to('root#auth_login');
  $r->get('/register')->to('register#index');
  $r->post('/register')->to('register#register');
  $r->any('/logout')->to('root#auth_logout');

  # Always available api routes
  $r->post('api/login')->to('api-auth#post_login');
  $r->post('api/register')->to('api-register#post_register');
  $r->post('api/logout')->to('api-auth#post_logout');

  my $api = $r->under('/api')->to('api-auth#auth');

  $api->post('/' => sub {
    return shift->render( json => {
      success => Mojo::JSON->true,
      message => 'Successful Auth',
    });
  });
  $api->post('/upload')->to('api-upload#post_upload');
  $api->post('/search')->to('api-upload#post_search');
  $api->post('/admin-approve')->to('api-admin#post_admin_approve');
  $api->post('/admin-merge')->to('api-admin#post_admin_merge');
  $api->post('/edit')->to('api-api#post_edit');
  $api->post('/fetchuser')->to('api-api#post_fetchuser');
  $api->post('/user-history')->to('api-user#post_user_history');

  my $admin_routes = $r->under('/admin')->to('admin#under');

  $admin_routes->get('/')->to('admin#home');
  $admin_routes->get('/tokens')->to('admin-tokens#index');
  $admin_routes->post('/tokens')->to('admin-tokens#create');
  $admin_routes->get('/tokens/:id')->to('admin-tokens#read');
  $admin_routes->post('/tokens/:id')->to('admin-tokens#update');
  $admin_routes->post('/tokens/:id/delete')->to('admin-tokens#delete');
  $admin_routes->get('/users')->to('admin-users#index');
  $admin_routes->get('/users/:id')->to('admin-users#read');
  $admin_routes->post('/users/:id')->to('admin-users#update');
  $admin_routes->post('/users/:id/delete')->to('admin-users#delete');

  my $user_routes = $r->under('/')->to('root#under');

  $user_routes->get('/home')->to('root#home');

  $self->hook( before_dispatch => sub {
    my $self = shift;

    $self->res->headers->header('Access-Control-Allow-Origin' => '*') if $self->app->mode eq 'development';
  });

  $self->helper( is_admin => sub {
    my ($c, $user_id) = @_;
    my $admin = $c->schema->resultset('Administrator')->find($user_id);
    return defined $admin;
  });

  $self->helper( create_hash => sub{
    my ($self, $id, $name, $fullAddress, $postcode) = @_;

    return {
      id => $id,
      name => $name,
      fullAddress => $fullAddress . ", " . $postcode,
    }
  });

  $self->helper(get_active_user_id => sub {
    my $self = shift;

    my $token = $self->get_session_token(); 
    if (! defined $token){
      return undef;
    }

    my @out = $self->db->selectrow_array("SELECT UserIdAssignedTo_FK FROM SessionTokens WHERE SessionTokenName = ?",undef,($token));
    if (! @out){
      return undef;
    }
    else{
      return $out[0];
    }
  });

  $self->helper(get_session_token => sub {
    my $self = shift;

    #See if logged in.
    my $sessionToken = undef;

    my $json = $self->req->json;
    if (defined $json) {
      $sessionToken = $json->{$self->app->config->{sessionTokenJsonName}};
    }

    if ( ! defined $sessionToken || $sessionToken eq "" ) {
      $sessionToken = $self->session->{$self->app->config->{sessionTokenJsonName}};
    }

    if (defined $sessionToken && $sessionToken eq "" ) {
      $sessionToken = undef;
    }

    return $sessionToken;
  });


  #This assumes the user has no current session on that device.
  $self->helper(generate_session => sub {
    my ($self, $userId) = @_;

    my $sessionToken = $self->generate_session_token();

    my $insertStatement = $self->db->prepare('INSERT INTO SessionTokens (SessionTokenName, UserIdAssignedTo_FK, ExpireDateTime) VALUES (?, ?, ?)');
    my $rowsAdded = $insertStatement->execute($sessionToken, $userId, DateTime->now()->add( years => 1 ));
    
    return $sessionToken;
  });

  $self->helper(generate_session_token => sub {
    my $self = shift;
    return Data::UUID->new->create_str();
  });

  $self->helper(does_organisational_id_exist => sub {
    my ( $c, $org_id ) = @_;
    return defined $c->schema->resultset('Organisation')->find({ organisationalid => $org_id });
  });

  $self->helper(get_age_foreign_key => sub {
    my ( $c, $age_string ) = @_;
    my $age_range = $c->schema->resultset('AgeRange')->find({ agerangestring => $age_string });
    return defined $age_range ? $age_range->agerangeid : undef;
  });
}

1;
