package Pear::LocalLoop::Command::codepoint_open;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

use Geo::UK::Postcode::CodePointOpen;

has description => 'Manage Codepoint Open Data';

has usage => sub { shift->extract_usage };

sub run {
  my ( $self, @args ) = @_;

  getopt \@args,
    'o|outcodes=s' => \my @outcodes,
    'q|quiet'      => \my $quiet_mode;

  my $cpo_dir = $self->app->home->child('etc')->child('code-point-open');
  my $zip_file = $cpo_dir->child('codepo_gb.zip')->realpath->to_string;
  my $output_dir = $cpo_dir->child('codepo_gb')->realpath->to_string;

  unless ( -d $output_dir ) {
    print "Unzipping code-point-open data\n" unless $quiet_mode;
    eval { system( 'unzip', '-q', $zip_file, '-d', $output_dir ) };
    if ( my $err = $@ ) {
        print "Error extracting zip: " . $err . "\n";
        print "Manually create etc/code-point-open/codepo_gb directory and extract zip into it";
        die;
    }
  }

  my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => $output_dir );

  printf( "Importing data for %s outcode(s)\n", @outcodes ? join( ' ', @outcodes ) : 'all' )
    unless $quiet_mode;

  my $iter = $cpo->read_iterator(
    outcodes => \@outcodes,
    include_lat_long => 1,
    split_postcode => 1,
  );

  my $pc_rs = $self->app->schema->resultset('GbPostcode');
  while ( my $pc = $iter->() ) {
    $pc_rs->find_or_create(
      {
        outcode   => $pc->{Outcode},
        incode    => $pc->{Incode},
        latitude  => $pc->{Latitude},
        longitude => $pc->{Longitude},
      },
      { key => 'primary' },
    );
  }
}

=head1 SYNOPSIS

  Usage: APPLICATION codepoint_open [OPTIONS]

  Options:

    -o|--outcodes <outcode> : limit to specified outcodes (can be defined
                              multiple times)

=cut

1;
