package Pear::LocalLoop::Import::Role::CSV;
use strict;
use warnings;
use Moo::Role;
use Text::CSV;
use Try::Tiny;
use Pear::LocalLoop::Error;

requires 'csv_required_columns';

has csv_file => (
  is       => 'ro',
  predicate => 1,
);

has csv_string => (
  is => 'ro',
  predicate => 1,
);

has csv_error => (
  is => 'ro',
  predicate => 1,
);

has _csv_filehandle => (
  is      => 'lazy',
  builder => sub {
    my $self = shift;
    my $fh;
    if ( $self->has_csv_file ) {
      open $fh, '<', \${$self->csv_file};
    } elsif ( $self->has_csv_string ) {
      my $string = $self->csv_string;
      open $fh, '<', \$string;
    } else {
      die "Must provide csv_file or csv_string"
    }
    return $fh;
  }
);

has text_csv_options => (
  is      => 'lazy',
  builder => sub {
    return {
      binary           => 1,
      allow_whitespace => 1,
    };
  }
);

has _text_csv => (
  is      => 'lazy',
  builder => sub {
    return Text::CSV->new(shift->text_csv_options);
  }
);

has csv_data => (
  is      => 'lazy',
  builder => sub {
    my $self = shift;
    my $header_check = $self->check_headers;
    return 0 unless $header_check;
    return $self->_text_csv->getline_hr_all( $self->_csv_filehandle );
  }
);

sub check_headers {
  my $self = shift;
  my $req_headers = $self->csv_required_columns;
  use Devel::Dwarn;
  Dwarn $req_headers;
  # TODO catch the boom
  my @headers;
  try {
    @headers = $self->_text_csv->header( $self->_csv_filehandle );
  } catch {
    $self->csv_error = $_->[1];
  };
  return 0 unless @headers;
  Dwarn \@headers;
  my %header_map = ( map { $_ => 1 } @headers );
  for my $req_header ( @$req_headers ) {
    next if $header_map{$req_header};
    die "Require header [" . $req_header . "]";
  }
  return 1;
}

1;
