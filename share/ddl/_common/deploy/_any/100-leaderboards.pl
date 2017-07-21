#! perl

use strict;
use warnings;

use DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader({ naming => 'v7' }, sub {
  my $schema = shift;

  $schema->resultset('Leaderboard')->populate([
    [ qw/ name type / ],
    [ 'Daily Total', 'daily_total' ],
    [ 'Daily Count', 'daily_count' ],
    [ 'Weekly Total', 'weekly_total' ],
    [ 'Weekly Count', 'weekly_count' ],
    [ 'Monthly Total', 'monthly_total' ],
    [ 'Monthly Count', 'monthly_count' ],
    [ 'All Time Total', 'all_time_total' ],
    [ 'All Time Count', 'all_time_count' ],
  ]);

});
