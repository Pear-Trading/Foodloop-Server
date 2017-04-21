package Pear::LocalLoop;

use Mojo::Base 'Mojolicious';
use Data::UUID;
use Mojo::JSON;
use Pear::LocalLoop::Schema;
use DateTime;
use Mojo::Asset::File;
use Mojo::File qw/ path tempdir /;

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
      storage_path => tempdir,
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
            return $user->id;
        }
      }
      return undef;
    },
  });

  # shortcut for use in template
  $self->helper( db => sub { warn "DEPRECATED db helper"; return $self->app->schema->storage->dbh });
  $self->helper( schema => sub { $self->app->schema });

  $self->helper( api_validation_error => sub {
    my $c = shift;
    my $failed_vals = $c->validation->failed;
    for my $val ( @$failed_vals ) {
      my $check = shift @{ $c->validation->error($val) };
      return $c->render(
        json => {
          success => Mojo::JSON->false,
          message => $c->error_messages->{$val}->{$check}->{message},
        },
        status => $c->error_messages->{$val}->{$check}->{status},
      );
    }
  });

  $self->helper( get_path_from_uuid => sub {
    my $c = shift;
    my $uuid = shift;
    my ( $folder ) = $uuid =~ /(..)/;
    return path($c->app->config->{storage_path}, $folder, $uuid);
  });

  $self->helper( store_file_from_upload => sub {
    my $c = shift;
    my $upload = shift;
    my $uuid = Data::UUID->new->create_str;
    my $path = $c->get_path_from_uuid( $uuid );
    $path->dirname->make_path;
    $upload->move_to( $path );
    return $uuid;
  });

  $self->helper( get_file_from_uuid => sub {
    my $c = shift;
    my $uuid = shift;
    return Mojo::Asset::File->new( path => $c->get_path_from_uuid( $uuid ) );
  });

  my $r = $self->routes;
  $r->get('/')->to('root#index');
  $r->post('/')->to('root#auth_login');
  $r->get('/register')->to('register#index');
  $r->post('/register')->to('register#register');
  $r->any('/logout')->to('root#auth_logout');

  # Always available api routes
  my $api_public = $r->under('/api')->to('api-auth#check_json');

  $api_public->post('/login')->to('api-auth#post_login');
  $api_public->post('/register')->to('api-register#post_register');
  $api_public->post('/logout')->to('api-auth#post_logout');

  # Private, must be authenticated api routes
  my $api = $api_public->under('/')->to('api-auth#auth');

  $api->post('/' => sub {
    return shift->render( json => {
      success => Mojo::JSON->true,
      message => 'Successful Auth',
    });
  });
  $api->post('/upload')->to('api-upload#post_upload');
  $api->post('/search')->to('api-upload#post_search');
  $api->post('/edit')->to('api-api#post_edit');
  $api->post('/fetchuser')->to('api-api#post_fetchuser');
  $api->post('/user-history')->to('api-user#post_user_history');

  my $api_admin = $api->under('/')->to('api-admin#auth');

  $api_admin->post('/admin-approve')->to('api-admin#post_admin_approve');
  $api_admin->post('/admin-merge')->to('api-admin#post_admin_merge');

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

  $user_routes->post('/portal/upload')->to('portal#post_upload');

  $self->hook( before_dispatch => sub {
    my $self = shift;

    $self->res->headers->header('Access-Control-Allow-Origin' => '*') if $self->app->mode eq 'development';
  });
}

1;
