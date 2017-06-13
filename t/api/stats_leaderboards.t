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
};

$schema->resultset('AccountToken')->create({ name => $_->{token} })
  for ( $user1, $user2, $user3, $user4, $org );

$framework->register_customer($_)
  for ( $user1, $user2, $user3, $user4 );

$framework->register_organisation($org);

my $org_result = $schema->resultset('Organisation')->find({ name => $org->{name} });

my $tweak = 0;

my $now = DateTime->today();

{
  my $user_result = $schema->resultset('User')->find({ email => $user1->{email} });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 1,
    proof_image => 'a',
  });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 9,
    proof_image => 'a',
    submitted_at => $dtf->format_datetime($now->clone->subtract( days => 1 )),
  });
}

{
  my $user_result = $schema->resultset('User')->find({ email => $user2->{email} });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 3,
    proof_image => 'a',
  });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 1,
    proof_image => 'a',
    submitted_at => $dtf->format_datetime($now->clone->subtract( days => 1 )),
  });
}

{
  my $user_result = $schema->resultset('User')->find({ email => $user3->{email} });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 5,
    proof_image => 'a',
  });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 5,
    proof_image => 'a',
    submitted_at => $dtf->format_datetime($now->clone->subtract( days => 1 )),
  });
}

{
  my $user_result = $schema->resultset('User')->find({ email => $user4->{email} });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 9,
    proof_image => 'a',
  });

  $user_result->create_related( 'transactions', {
    seller_id => $org_result->id,
    value => 3,
    proof_image => 'a',
    submitted_at => $dtf->format_datetime($now->clone->subtract( days => 1 )),
  });
}

my $session_key = $framework->login({
  email    => $user1->{email},
  password => $user1->{password},
});

sub test_leaderboard {
  my ( $title, $name, $date, $expected, $user_place ) = @_;

  subtest $title => sub {
    my $leaderboard_rs = $schema->resultset('Leaderboard');

    $leaderboard_rs->create_new( $name, $date );
    
    $t->post_ok('/api/stats/leaderboard' => json => { session_key => $session_key, type => $name } )
      ->status_is(200)
      ->or($framework->dump_error)
      ->json_is('/success', Mojo::JSON->true)
      ->or($framework->dump_error)
      ->json_is('/leaderboard', $expected)
      ->or($framework->dump_error)
      ->json_is('/user_position', $user_place)
      ->or($framework->dump_error);
  };
}

$schema->resultset('Leaderboard')->create_new( 'daily_total', $now->clone->subtract( days => 1 ) );

test_leaderboard(
  'Daily Total',
  'daily_total',
  $now,
  [
    { display_name => 'Test User4', value => 9, trend => 1 },
    { display_name => 'Test User3', value => 5, trend => 0 },
    { display_name => 'Test User2', value => 3, trend => 1 },
    { display_name => 'Test User1', value => 1, trend => -1},
  ],
  3
);

test_leaderboard(
  'Daily Count',
  'daily_count',
  $now,
  [
    { display_name => 'Test User1', value => 1, trend => 0 },
    { display_name => 'Test User2', value => 1, trend => 0 },
    { display_name => 'Test User3', value => 1, trend => 0 },
    { display_name => 'Test User4', value => 1, trend => 0 },
  ],
  0
);

done_testing;
