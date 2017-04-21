package Test::Pear::LocalLoop;
use Mojo::Base -base;

use File::Temp;
use Test::Mojo;

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

1;
