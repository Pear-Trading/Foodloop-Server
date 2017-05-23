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
  age_range    => 1,
};

my $user2 = {
  token        => 'b',
  full_name    => 'Test User2',
  display_name => 'Test User2',
  email        => 'test2@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  age_range    => 1,
};

my $user3 = {
  token        => 'c',
  full_name    => 'Test User3',
  display_name => 'Test User3',
  email        => 'test3@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  age_range    => 1,
};

my $user4 = {
  token        => 'd',
  full_name    => 'Test User4',
  display_name => 'Test User4',
  email        => 'test4@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  age_range    => 1,
};

my $org = {
  token       => 'e',
  email       => 'test5@example.com',
  name        => 'Test Org',
  street_name => 'Test Street',
  town        => 'Lancaster',
  postcode    => 'LA1 1AA',
  password    => 'abc123',
};

$schema->resultset('AccountToken')->create({ name => $_->{token} })
  for ( $user1, $user2, $user3, $user4, $org );

$framework->register_customer($_)
  for ( $user1, $user2, $user3, $user4 );

$framework->register_organisation($org);

my $org_result = $schema->resultset('Organisation')->find({ name => $org->{name} });

my $tweak = 0;

for my $user ( $user1, $user2, $user3, $user4 ) {
  $tweak ++;
  my $user_result = $schema->resultset('User')->find({ email => $user->{email} });
  for ( 1 .. 10 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
    });
  }

  for ( 11 .. 20 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      submitted_at => $dtf->format_datetime(DateTime->today()->subtract( days => 5 )),
    });
  }

  for ( 21 .. 30 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      submitted_at => $dtf->format_datetime(DateTime->today()->subtract( days => 25 )),
    });
  }

  for ( 31 .. 40 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      submitted_at => $dtf->format_datetime(DateTime->today()->subtract( days => 50 )),
    });
  }

  is $user_result->transactions->count, 40, 'correct count for user' . $tweak;
}

sub test_leaderboard {
  my ( $title, $name, $date, $expected ) = @_;

  subtest $title => sub {
    my $leaderboard_rs = $schema->resultset('Leaderboard');

    my $today_board = $leaderboard_rs->find({ type => $name })->create_new($date)->sets->first;

    is $today_board->values->count, 5, 'correct value count for today';

    my $today_values = $today_board->values->search(
      {},
      {
        order_by => { -desc => 'value' },
        columns => [ qw/ user_id value / ],
      },
    );
    $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

    is_deeply [ $today_values->all ], $expected, 'Today as expected';
  };
}

test_leaderboard(
  'Daily Total',
  'daily_total',
  DateTime->today,
  [
    { user_id => 4, value => 95 },
    { user_id => 3, value => 85 },
    { user_id => 2, value => 75 },
    { user_id => 1, value => 65 },
    { user_id => 5, value => 0 },
  ]
);

test_leaderboard(
  'Daily Count',
  'daily_count',
  DateTime->today,
  [
    { user_id => 1, value => 10 },
    { user_id => 2, value => 10 },
    { user_id => 3, value => 10 },
    { user_id => 4, value => 10 },
    { user_id => 5, value => 0 },
  ]
);

test_leaderboard(
  'Weekly Total',
  'weekly_total',
  DateTime->today->subtract( days => 7 ),
  [
    { user_id => 4, value => 195 },
    { user_id => 3, value => 185 },
    { user_id => 2, value => 175 },
    { user_id => 1, value => 165 },
    { user_id => 5, value => 0 },
  ]
);

done_testing;
