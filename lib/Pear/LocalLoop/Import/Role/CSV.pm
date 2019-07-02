package Pear::LocalLoop::Import::Role::CSV;
use strict;
use warnings;
use Moo::Role;
use Text::CSV;

requires 'csv_required_columns';

has csv_file => (
  is       => 'ro',
  required => 1,
);

has _csv_filehandle => (
  is      => 'lazy',
  builder => sub {
    open my $fh, '<', $self->csv_file;
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
  }
);

1;