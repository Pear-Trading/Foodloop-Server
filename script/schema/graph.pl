#! /usr/bin/env perl
use strict;
use warnings;

use feature "say";

use FindBin qw/ $Bin /;
use lib "$Bin/../../lib";

use SQL::Translator;
use Pear::LocalLoop::Schema;

say "Setting up Translator and Schema";

my $schema = Pear::LocalLoop::Schema->connect;
my $tr = SQL::Translator->new(
  from => "SQL::Translator::Parser::DBIx::Class",
  to => 'GraphViz',
  debug => 1,
  trace => 1,
  producer_args => {
    out_file => "$Bin/../../schema.png",
    output_type => 'png',
    width => 0,
    height => 0,
    show_constraints => 1,
    show_datatypes => 1,
    show_sizes => 1,
  },
);

say "Translating Schema to image";

$tr->translate( data => $schema );

say "Finished";
