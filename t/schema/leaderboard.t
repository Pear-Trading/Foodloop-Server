use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;
my $dtf = $schema->storage->datetime_parser;

my $user1 = {
  token        => 'a',
  full_name    => 'Test User1',
  display_name => 'Test User1',
  email        => 'test1@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $user2 = {
  token        => 'b',
  full_name    => 'Test User2',
  display_name => 'Test User2',
  email        => 'test2@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $user3 = {
  token        => 'c',
  full_name    => 'Test User3',
  display_name => 'Test User3',
  email        => 'test3@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $user4 = {
  token        => 'd',
  full_name    => 'Test User4',
  display_name => 'Test User4',
  email        => 'test4@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $org = {
  token       => 'e',
  email       => 'test5@example.com',
  name        => 'Test Org',
  street_name => 'Test Street',
  town        => 'Lancaster',
  postcode    => 'LA1 1AA',
  password    => 'abc123',
  sector      => 'A',
};

$schema->resultset('AccountToken')->create({ name => $_->{token} })
  for ( $user1, $user2, $user3, $user4, $org );

$framework->register_customer($_)
  for ( $user1, $user2, $user3, $user4 );

$framework->register_organisation($org);

my $org_result = $schema->resultset('Organisation')->find({ name => $org->{name} });

my $tweak = 0;

my $now = DateTime->today();

for my $user ( $user1, $user2, $user3, $user4 ) {
  $tweak ++;
  my $user_result = $schema->resultset('User')->find({ email => $user->{email} })->entity;
  for ( 1 .. 10 ) {
    $user_result->create_related( 'purchases', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
    });
  }

  for ( 11 .. 20 ) {
    $user_result->create_related( 'purchases', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      purchase_time => $dtf->format_datetime($now->clone->subtract( days => 5 )),
    });
  }

  for ( 21 .. 30 ) {
    $user_result->create_related( 'purchases', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      purchase_time => $dtf->format_datetime($now->clone->subtract( days => 25 )),
    });
  }

  for ( 31 .. 40 ) {
    $user_result->create_related( 'purchases', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      purchase_time => $dtf->format_datetime($now->clone->subtract( days => 50 )),
    });
  }

  is $user_result->purchases->count, 40, 'correct count for user' . $tweak;
}

sub test_leaderboard {
  my ( $title, $name, $date, $expected ) = @_;

  subtest $title => sub {
    my $leaderboard_rs = $schema->resultset('Leaderboard');

    my $today_board = $leaderboard_rs->find({ type => $name })->create_new($date)->get_latest;

    is $today_board->values->count, 4, 'correct value count';

    my $today_values = $today_board->values->search(
      {},
      {
        order_by => { -desc => 'value' },
        columns => [ qw/ entity_id value / ],
      },
    );
    $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

    is_deeply [ $today_values->all ], $expected, 'array as expected';
  };
}

test_leaderboard(
  'Daily Total',
  'daily_total',
  $now,
  [
    { entity_id => 4, value => 95 },
    { entity_id => 3, value => 85 },
    { entity_id => 2, value => 75 },
    { entity_id => 1, value => 65 },
  ]
);

test_leaderboard(
  'Daily Count',
  'daily_count',
  $now,
  [
    { entity_id => 1, value => 10 },
    { entity_id => 2, value => 10 },
    { entity_id => 3, value => 10 },
    { entity_id => 4, value => 10 },
  ]
);

test_leaderboard(
  'Weekly Total',
  'weekly_total',
  $now->clone->subtract( days => 7 ),
  [
    { entity_id => 4, value => 195 },
    { entity_id => 3, value => 185 },
    { entity_id => 2, value => 175 },
    { entity_id => 1, value => 165 },
  ]
);

test_leaderboard(
  'Weekly Count',
  'weekly_count',
  $now->clone->subtract( days => 7 ),
  [
    { entity_id => 1, value => 10 },
    { entity_id => 2, value => 10 },
    { entity_id => 3, value => 10 },
    { entity_id => 4, value => 10 },
  ]
);

test_leaderboard(
  'Monthly Total',
  'monthly_total',
  $now->clone->subtract( months => 1 ),
  [
    { entity_id => 4, value => 490 },
    { entity_id => 3, value => 470 },
    { entity_id => 2, value => 450 },
    { entity_id => 1, value => 430 },
  ]
);

test_leaderboard(
  'Monthly Count',
  'monthly_count',
  $now->clone->subtract( months => 1 ),
  [
    { entity_id => 1, value => 20 },
    { entity_id => 2, value => 20 },
    { entity_id => 3, value => 20 },
    { entity_id => 4, value => 20 },
  ]
);

test_leaderboard(
  'All Time Total',
  'all_time_total',
  $now,
  [
    { entity_id => 4, value => 885 },
    { entity_id => 3, value => 855 },
    { entity_id => 2, value => 825 },
    { entity_id => 1, value => 795 },
  ]
);

test_leaderboard(
  'All Time Count',
  'all_time_count',
  $now,
  [
    { entity_id => 1, value => 30 },
    { entity_id => 2, value => 30 },
    { entity_id => 3, value => 30 },
    { entity_id => 4, value => 30 },
  ]
);

subtest 'get_latest' => sub {
  my $leaderboard_rs = $schema->resultset('Leaderboard');
  $leaderboard_rs->find({ type => 'daily_total' })->create_new($now->clone->subtract(days => 5));
  $leaderboard_rs->find({ type => 'daily_total' })->create_new($now->clone->subtract(days => 25));
  $leaderboard_rs->find({ type => 'daily_total' })->create_new($now->clone->subtract(days => 50));

  my $today_board = $leaderboard_rs->find({ type => 'daily_total' })->get_latest;

  is $today_board->values->count, 4, 'correct value count';

  my $today_values = $today_board->values->search(
    {},
    {
      order_by => { -desc => 'value' },
      columns => [ qw/ entity_id value / ],
    },
  );
  $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

  my $expected = [
    { entity_id => 4, value => 95 },
    { entity_id => 3, value => 85 },
    { entity_id => 2, value => 75 },
    { entity_id => 1, value => 65 },
  ];

  is_deeply [ $today_values->all ], $expected, 'array as expected';

  is $leaderboard_rs->find({ type => 'daily_total' })->sets->count, 4, 'correct leaderboard count';
};

done_testing;
