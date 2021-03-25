package Test::Pear::LocalLoop;
use Moo;

use Test::More;
use File::Temp;
use Test::Mojo;
use DateTime::Format::Strptime;
use DBIx::Class::Fixtures;

# Conditionally require Test::PostgreSQL
sub BUILD {
    if ( $ENV{PEAR_TEST_PG} ) {
        require Test::PostgreSQL
          or die "you need Test::PostgreSQL to run PG testing";
        Test::PostgreSQL->import;
    }

    return 1;
}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;

    if ( $ENV{PEAR_TEST_PG} && !$in_global_destruction ) {
        $self->mojo->app->schema->storage->dbh->disconnect;
        $self->pg->stop;
    }

    return 1;
}

has pg => (
    is      => 'lazy',
    builder => sub {
        return Test::PostgreSQL->new();
    },
);

has config => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        my $file = File::Temp->new;

        my $dsn;

        if ( $ENV{PEAR_TEST_PG} ) {
            $dsn = $self->pg->dsn;
        }
        else {
            $dsn = "dbi:SQLite::memory:";
        }

        print $file <<"END";
{
  dsn => "$dsn",
  user => undef,
  pass => undef,
}
END

        $file->seek( 0, SEEK_END );
        return $file;
    },
);

has mojo => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;

        local $ENV{MOJO_CONFIG} = $self->config->filename;

        my $t = Test::Mojo->new('Pear::LocalLoop');
        $t->app->schema->deploy;

        return $t;
    },
);

has etc_dir => (
    is      => 'lazy',
    builder => sub { die "etc dir not set" },
);

has _deployed => (
    is      => 'rwp',
    default => 0,
);

sub framework {
    my $self        = shift;
    my $no_populate = shift;

    my $t      = $self->mojo;
    my $schema = $t->app->schema;

    unless ( $no_populate || $self->_deployed ) {
        $schema->resultset('Leaderboard')->populate(
            [
                [qw/ name type /],
                [ 'Daily Total',    'daily_total' ],
                [ 'Daily Count',    'daily_count' ],
                [ 'Weekly Total',   'weekly_total' ],
                [ 'Weekly Count',   'weekly_count' ],
                [ 'Monthly Total',  'monthly_total' ],
                [ 'Monthly Count',  'monthly_count' ],
                [ 'All Time Total', 'all_time_total' ],
                [ 'All Time Count', 'all_time_count' ],
            ]
        );
    }

    $self->_set__deployed(1);

    return $t;
}

sub dump_error {
    return sub {
        my $self = shift;
        if ( my $error = $self->tx->res->dom->at('pre[id="error"]') ) {
            diag $error->text;
        }
        elsif ( my $route_error =
            $self->tx->res->dom->at('div[id="routes"] > p') )
        {
            diag $route_error->content;
        }
        else {
            diag $self->tx->res->to_string;
        }
    };
}

sub register_customer {
    my $self = shift;
    my $args = shift;

    my $json = {
        usertype => 'customer',
        %$args,
    };

    $self->framework->post_ok( '/api/register' => json => $json )
      ->status_is(200)->or( $self->dump_error )
      ->json_is( '/success', Mojo::JSON->true )->or( $self->dump_error );

    return 1;
}

sub register_organisation {
    my ( $self, $args ) = @_;

    $args->{usertype} = 'organisation';

    $self->framework->post_ok( '/api/register' => json => $args )
      ->status_is(200)->or( $self->dump_error )
      ->json_is( '/success', Mojo::JSON->true )->or( $self->dump_error );

    return 1;
}

sub login {
    my $self = shift;
    my $args = shift;

    $self->framework->post_ok( '/api/login' => json => $args )->status_is(200)
      ->or( $self->dump_error )->json_is( '/success', Mojo::JSON->true )
      ->or( $self->dump_error );

    return $self->framework->tx->res->json->{session_key};
}

sub logout {
    my $self        = shift;
    my $session_key = shift;

    $self->framework->post_ok(
        '/api/logout' => json => { session_key => $session_key } )
      ->status_is(200)->json_is( '/success', Mojo::JSON->true )
      ->json_like( '/message', qr/Logged Out/ );

    return 1;
}

sub gen_upload {
    my ( $self, $args ) = @_;

    my $file = {
        content        => '',
        filename       => 'text.jpg',
        'Content-Type' => 'image/jpeg',
    };

    return {
        json => Mojo::JSON::encode_json($args),
        file => $file,
    };
}

sub install_fixtures {
    my ( $self, $fixture_name ) = @_;

    my $fixtures = DBIx::Class::Fixtures->new(
        {
            config_dir =>
              File::Spec->catdir( $self->etc_dir, 'fixtures', 'config' ),
        }
    );

    my $t      = $self->framework(1);
    my $schema = $t->app->schema;

    $fixtures->populate(
        {
            directory => File::Spec->catdir(
                $self->etc_dir, 'fixtures', 'data', $fixture_name
            ),
            no_deploy => 1,
            schema    => $schema,
        }
    );

    # Reset table id sequences
    if ( $ENV{PEAR_TEST_PG} ) {
        $schema->storage->dbh_do(
            sub {
                my ( $storage, $dbh, $sets ) = @_;
                for my $table ( keys %$sets ) {
                    my $seq = $sets->{$table};
                    $dbh->do(
                        qq/
          SELECT setval(
            '$seq',
            COALESCE(
              (SELECT MAX(id)+1 FROM $table),
              1
            ),
            false
          );
          /
                    );
                }
            },
            {
                entities      => 'entities_id_seq',
                organisations => 'organisations_id_seq',
                users         => 'users_id_seq',
                customers     => 'customers_id_seq',
            }
        );
    }

    return 1;
}

1;
