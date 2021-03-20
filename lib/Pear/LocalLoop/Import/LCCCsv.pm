package Pear::LocalLoop::Import::LCCCsv;
use Moo;
use Pear::LocalLoop::Error;

has external_name => (
    is      => 'ro',
    default => 'LCC CSV',
);

has csv_required_columns => (
    is      => 'lazy',
    builder => sub {
        Pear::LocalLoop::ImplementationError->throw(
            "Must be implemented by child class");
    },
);

with qw/
  Pear::LocalLoop::Import::Role::ExternalName
  Pear::LocalLoop::Import::Role::Schema
  Pear::LocalLoop::Import::Role::CSV
  /;

1;
