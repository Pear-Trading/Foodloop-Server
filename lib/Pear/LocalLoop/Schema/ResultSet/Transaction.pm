package Pear::LocalLoop::Schema::ResultSet::Transaction;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

use DateTime;

sub today_rs {
  my ( $self ) = @_;

  my $dtf = $self->result_source->schema->storage->datetime_parser;
  return $self->search({
    submitted_at => {
      -between => [
        $dtf->format_datetime(DateTime->today()),
        $dtf->format_datetime(DateTime->today()->add( days => 1 )),
      ],
    },
  });
}

sub today_for_user {
  my ( $self, $user ) = @_;
  return $self->search({ buyer_id => $user->id })->today_rs;
}

1;
