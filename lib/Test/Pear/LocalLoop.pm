package Test::Pear::LocalLoop;
use Mojo::Base -base;

use Test::More;
use File::Temp;
use Test::Mojo;
use DateTime::Format::Strptime;

has config => sub {
  my $file = File::Temp->new;

  print $file <<'END';
{
  dsn => "dbi:SQLite::memory:",
  user => undef,
  pass => undef,
}
END

  $file->seek( 0, SEEK_END );
  return $file;
};

has framework => sub {
  my $self = shift;

  $ENV{MOJO_CONFIG} = $self->config->filename;

  my $t = Test::Mojo->new('Pear::LocalLoop');
  my $schema = $t->app->schema;
  $schema->deploy;

  $schema->resultset('AgeRange')->populate([
    [ qw/ string / ],
    [ '20-35' ],
    [ '35-50' ],
    [ '50+' ],
  ]);

  return $t;
};

sub dump_error {
  return sub {
    my $self = shift;
    if ( my $error = $self->tx->res->dom->at('pre[id="error"]') ) {
      diag $error->text;
    } else {
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

  $self->framework->post_ok('/api/register' => json => $json)
    ->status_is(200)->or($self->dump_error)
    ->json_is('/success', Mojo::JSON->true)->or($self->dump_error);
}

sub login {
  my $self = shift;
  my $args = shift;

  $self->framework->post_ok('/api/login' => json => $args)
    ->status_is(200)->or($self->dump_error)
    ->json_is('/success', Mojo::JSON->true)->or($self->dump_error);

  return $self->framework->tx->res->json->{session_key};
}

1;
