package Pear::LocalLoop::Import::LCCCsv::Suppliers;
use Moo;

extends qw/Pear::LocalLoop::Import::LCCCsv/;

sub import {
  my $self = shift;

  $import = Pear::LocalLoop::Import::LCCCsv->new;
}

sub _row_to_result {
  my ( $self, $row ) = @_;


}

1;
