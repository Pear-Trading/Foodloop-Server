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
    { quote_names => 1 },
  );
};

sub startup {
  my $self = shift;

  my $version = `git describe --tags`;

  $self->plugin('Config', {
    default => {
      storage_path => tempdir,
      sessionTimeSeconds => 60 * 60 * 24 * 7,
      sessionTokenJsonName => 'session_key',
      sessionExpiresJsonName => 'sessionExpires',
      version => $version,
    },
  });
  my $config = $self->config;

  push @{ $self->commands->namespaces }, __PACKAGE__ . '::Command';

  $self->plugin('Pear::LocalLoop::Plugin::BootstrapPagination', { bootstrap4 => 1 } );
  $self->plugin('Pear::LocalLoop::Plugin::Validators');
  $self->plugin('Pear::LocalLoop::Plugin::Datetime');
  $self->plugin('Pear::LocalLoop::Plugin::Postcodes');
  $self->plugin('Pear::LocalLoop::Plugin::TemplateHelpers');

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
      return;
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
          error => $c->error_messages->{$val}->{$check}->{error} || $check,
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
  $r->get('/admin')->to('admin#index');
  $r->post('/admin')->to('admin#auth_login');
#  $r->get('/register')->to('register#index');
#  $r->post('/register')->to('register#register');
  $r->any('/admin/logout')->to('admin#auth_logout');

  my $api_public_get = $r->under('/api' => sub {
    my $c = shift;
    $c->res->headers->header('Access-Control-Allow-Origin'=> '*');
    $c->res->headers->header('Access-Control-Allow-Credentials' => 'true');
    $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, OPTIONS, POST, DELETE, PUT');
    $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, X-CSRF-Token');
    $c->res->headers->header('Access-Control-Max-Age' => '1728000');
  });

  $api_public_get->options('*' => sub {
    my $c = shift;
    $c->respond_to(any => { data => '', status => 200 });
  });

  # Always available api routes
  my $api_public = $api_public_get->under('/')->to('api-auth#check_json');

  $api_public->post('/login')->to('api-auth#post_login');
  $api_public->post('/register')->to('api-register#post_register');
  $api_public->post('/logout')->to('api-auth#post_logout');
  $api_public->post('/feedback')->to('api-feedback#post_feedback');

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
  $api->post('/user')->to('api-user#post_account');
  $api->post('/user/account')->to('api-user#post_account_update');
  $api->post('/user-history')->to('api-user#post_user_history');
  $api->post('/stats')->to('api-stats#post_index');
  $api->post('/stats/leaderboard')->to('api-stats#post_leaderboards');
  $api->post('/outgoing-transactions')->to('api-transactions#post_transaction_list_purchases');


  my $api_v1 = $api->under('/v1');

  my $api_v1_supplier = $api_v1->under('/supplier');

  $api_v1_supplier->post('/location')->to('api-v1-supplier-location#index');

  my $api_v1_org = $api_v1->under('/organisation')->to('api-v1-organisation#auth');

  $api_v1_org->post('/graphs')->to('api-v1-organisation-graphs#index');
  $api_v1_org->post('/snippets')->to('api-v1-organisation-snippets#index');
  $api_v1_org->post('/payroll')->to('api-organisation#post_payroll_read');
  $api_v1_org->post('/payroll/add')->to('api-organisation#post_payroll_add');
  $api_v1_org->post('/supplier')->to('api-organisation#post_supplier_read');
  $api_v1_org->post('/supplier/add')->to('api-organisation#post_supplier_add');
  $api_v1_org->post('/employee')->to('api-organisation#post_employee_read');
  $api_v1_org->post('/employee/add')->to('api-organisation#post_employee_add');

  my $admin_routes = $r->under('/admin')->to('admin#under');

  $admin_routes->get('/home')->to('admin#home');

  $admin_routes->get('/tokens')->to('admin-tokens#index');
  $admin_routes->post('/tokens')->to('admin-tokens#create');
  $admin_routes->get('/tokens/:id')->to('admin-tokens#read');
  $admin_routes->post('/tokens/:id')->to('admin-tokens#update');
  $admin_routes->post('/tokens/:id/delete')->to('admin-tokens#delete');

  $admin_routes->get('/users')->to('admin-users#index');
  $admin_routes->get('/users/:id')->to('admin-users#read');
  $admin_routes->post('/users/:id')->to('admin-users#update');
  $admin_routes->post('/users/:id/delete')->to('admin-users#delete');

  $admin_routes->get('/organisations')->to('admin-organisations#list');
  $admin_routes->get('/organisations/add')->to('admin-organisations#add_org');
  $admin_routes->post('/organisations/add')->to('admin-organisations#add_org_submit');
  $admin_routes->get('/organisations/:id')->to('admin-organisations#valid_read');
  $admin_routes->post('/organisations/:id')->to('admin-organisations#valid_edit');

  $admin_routes->get('/feedback')->to('admin-feedback#index');
  $admin_routes->get('/feedback/:id')->to('admin-feedback#read');

  $admin_routes->get('/transactions')->to('admin-transactions#index');
  $admin_routes->get('/transactions/:id')->to('admin-transactions#read');
  $admin_routes->get('/transactions/:id/image')->to('admin-transactions#image');
  $admin_routes->post('/transactions/:id/delete')->to('admin-transactions#delete');

  $admin_routes->get('/reports/transactions')->to('admin-reports#transaction_data');

#  my $user_routes = $r->under('/')->to('root#under');

# $user_routes->get('/home')->to('root#home');

#  my $portal_api = $r->under('/portal')->to('api-auth#check_json')->under('/')->to('portal#under');

#  $portal_api->post('/upload')->to('api-upload#post_upload');
#  $portal_api->post('/search')->to('api-upload#post_search');

  $self->hook( before_dispatch => sub {
    my $self = shift;

    $self->res->headers->header('Access-Control-Allow-Origin' => '*') if $self->app->mode eq 'development';
  });

  $self->helper( copy_transactions_and_delete => sub {
    my ( $c, $from_org, $to_org ) = @_;

    my $from_org_transaction_rs = $from_org->transactions;

    while ( my $from_org_transaction = $from_org_transaction_rs->next ) {
      $to_org->create_related(
        'transactions', {
          buyer_id      => $from_org_transaction->buyer_id,
          value         => $from_org_transaction->value,
          proof_image   => $from_org_transaction->proof_image,
          submitted_at  => $from_org_transaction->submitted_at,
          purchase_time => $from_org_transaction->purchase_time,
        }
      );
      $from_org_transaction->delete;
    }
    $from_org->delete;
  });
}

1;
