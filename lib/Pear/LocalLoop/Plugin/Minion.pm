package Pear::LocalLoop::Plugin::Minion;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Loader qw/ find_modules load_class /;

sub register {
  my ( $plugin, $app, $cong ) = @_;

  if ( defined $app->config->{minion} ) {
    $app->log->debug('Setting up Minion tasks');
    $app->plugin('Minion' => $app->config->{minion} );

    $app->log->debug('Loaded Minion Job packages:');

    my $job_namespace = __PACKAGE__ . '::Job';
    my @modules = find_modules $job_namespace;
    for my $package ( @modules ) {
      my ( $job ) = $package =~ /${job_namespace}::(.*)$/;
      $app->log->debug( $package );
      load_class $package;
      $app->minion->add_task(
        $job => sub {
          my ( $job, @args ) = @_;
          my $job_runner = $package->new(
            job => $job,
          );
          $job_runner->run( @args );
        }
      );
    }
    #  $app->minion->enqueue('test' => [ 'test arg 1', 'test_arg 2' ] );
  } else {
    $app->log->debug('No Minion Config');
  }

}

1;
