package Pear::LocalLoop::Schema::Script::DeploymentHandler;

use strict;
use warnings;

use MooX::Options::Actions;
use Module::Runtime qw/ use_module /;
use DBIx::Class::DeploymentHandler;

=head1 NAME

My::DeploymentScript - Deploy script using DBIx::Class::DeploymentHandler

=head1 SYNOPSIS

  use My::DeploymentScript;

  My::DeploymentScript->new_with_options( schema_class => 'My::Schema' );

=head1 DESCRIPTION

This module is for deploying and maintaining the ddl files, created by
DBIx::Class::DeploymentHandler.

=head1 OPTIONS

These are the options available on the command line

=head2 --connection ( -c )

This option is the connection you wish to deploy against, for example:

  "DBI:mysql:database=<db name>;hostname=<host>"

This option is then provided to the Schema's 'connect' function.

=cut

option connection => (
    is       => 'ro',
    format   => 's',
    required => 0,
    short    => 'c',
    doc      => "The DBI connection string to use",
);

=head2 --username ( -u )

The username to use for connection to the database

=cut

option username => (
    is      => 'ro',
    format  => 's',
    default => '',
    short   => 'u',
    doc     => "The username for the DB connection",
);

=head2 --password ( -p )

The password to use for connection to the database

=cut

option password => (
    is      => 'ro',
    format  => 's',
    default => '',
    short   => 'p',
    doc     => "The password for the supplied user",
);

=head2 --force ( -f )

This option will force the action if required - for example when overwriting
the same version of ddl items.

=cut

option force => (
    is      => 'ro',
    default => sub { 0 },
    short   => 'f',
    doc     => "Force the action if required",
);

=head2 --version ( -v )

This option allows you to select a specific verison for installing and generating
ddl.

=cut

option version => (
    is      => 'ro',
    format  => 'i',
    default => sub { shift->dh->schema->schema_version },
    short   => 'v',
    doc     => "Version to use as target",
);

=head1 ATTRIBUTES

These are options which can be passed to the constructor of the script

=head2 schema_class

This is the class of the schema you would like to connect to. This is required
to be defined in the 'new_with_options' call.

=cut

has schema_class => (
    is       => 'ro',
    required => 1,
);

=head2 schema

This is the connected schema. This uses the 'schema_class' attribute and
'connection' option to provide a DBIx::Class schema connection.

=cut

has schema => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        return use_module( $self->schema_class )
          ->connect( $self->connection, $self->username, $self->password, );
    },
);

=head2 script_directory

This is the directory where the DeploymentHandler scripts will be put for all
versions. Defaults to 'share/ddl'.

=cut

has script_directory => (
    is      => 'ro',
    default => 'share/ddl',
);

=head2 databases

This is an arrayref of the database types to prepare ddl scripts for. This
defaults to returning the following:

  [
    'mysql',
  ]

=cut

has databases => (
    is      => 'ro',
    default => sub { [qw/ PostgreSQL SQLite /] },
);

=head2 dh

This returns the actual DeploymentHandler, set up using the 'schema',
'script_directory', and 'database' attributes, and the 'force' option.

=cut

has dh => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        return DBIx::Class::DeploymentHandler->new(
            {
                schema           => $self->schema,
                force_overwrite  => $self->force,
                script_directory => $self->script_directory,
                databases        => $self->databases,
            }
        );
    }
);

=head1 COMMANDS

These are the available commands

=head2 write_ddl

This will create the ddl files required to perform an upgrade.

=cut

sub cmd_write_ddl {
    my ($self) = @_;

    $self->dh->prepare_install;
    my $v = $self->version;

    if ( $v > 1 ) {
        $self->dh->prepare_upgrade(
            {
                from_version => $v - 1,
                to_version   => $v,
            }
        );
    }
    
    return 1;
}

=head2 install_dh

This will install the tables required to use deployment handler on your
database. Only for use on a pre-existing database.

=cut

sub cmd_install_dh {
    my ($self) = @_;

    $self->dh->install_version_storage;
    $self->dh->add_database_version(
        {
            version => $self->version,
        }
    );
    
    return 1;
}

=head2 install

This command will install all the tables to the provided database

=cut

sub cmd_install {
    my ($self) = @_;

    $self->dh->install(
        {
            version => $self->version,
        }
    );
    
    return 1;
}

=head2 upgrade

This command will upgrade all tables to the latest versions

=cut

sub cmd_upgrade {
    my ($self) = @_;

    $self->dh->upgrade;
    
    return 1;
}

=head1 AUTHOR

Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>

=head1 SEE ALSO

* L<MooX::Options>
* L<DBIx::Class::DeploymentHandler>
* L<Module::Runtime>

=cut

1;
