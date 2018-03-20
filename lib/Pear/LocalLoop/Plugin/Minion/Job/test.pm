package Pear::LocalLoop::Plugin::Minion::Job::test;
use Mojo::Base -base;

has [ qw/ job / ];

sub run {
  my ( $self, @args ) = @_;

  $self->job->app->log->debug( 'Testing Job' );
  for my $arg ( @args ) {
    $self->job->app->log->debug( $arg );
  }
}

1;
