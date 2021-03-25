package Pear::LocalLoop::Plugin::Minion::Job;
use Mojo::Base -base;

has [qw/ job /];

has app => sub { shift->job->app };

sub run {
    die( __PACKAGE__ . " must implement run sub" );
}

1;
