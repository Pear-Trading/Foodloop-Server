package Pear::LocalLoop::Command::codepoint_open;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

use Geo::UK::Postcode::CodePointOpen;

has description => 'Manage Codepoint Open Data';

has usage => sub { shift->extract_usage };

sub run {
  my ( $self, @args ) = @_;

  my $cpo_dir = $self->app->home->child('etc')->child('code-point-open');
  my $zip_file = $cpo_dir->child('codepo_gb.zip')->realpath->to_string;
  my $output_dir = $cpo_dir->child('codepo_gb')->realpath->to_string;

  unless ( -d $output_dir ) {
    print "Unzipping code-point-open data\n";
    system( 'unzip', '-q', $zip_file, '-d', $output_dir );
  }

  my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => $output_dir );

use Devel::Dwarn;
my $i = 0;
  my $iter = $cpo->read_iterator(
    include_lat_long => 1,
    split_postcode => 1,
  );
while ( my $pc = $iter->() ) {
  Dwarn $pc;
  last if $i++ > 10;
}
}

=head1 SYNOPSIS

  Usage: APPLICATION codepoint_open [OPTIONS]

  Options:

    none, for now...

=cut

1;
