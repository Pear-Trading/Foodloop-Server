package Pear::LocalLoop::Controller::Api::V1::User::Medals;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw/true false/;

sub index {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  # Placeholder data
  my $global_placeholder = {
    group_name => {
      threshold => {
        awarded => true,
        awarded_at => '2017-01-02T01:00:00Z',
        threshold => 1,
        points => 1,
      },
      total => 1,
    },
  };

  my $organisation_placeholder = {
    org_id => {
      group_name => {
        threshold => {
          awarded => true,
          awarded_at => '2017-01-02T01:00:00Z',
          threshold => 1,
          points => 1,
          multiplier => 1,
        },
        total => 1,
      },
      name => 'Placeholder',
    },
  };

  # James test data
  my $entity = $c->stash->{api_user}->entity;

  my $now = DateTime->now;
  my $today = DateTime->today;
  my $week_ago = $today->clone->subtract( days => 7 );
  my $purchase_rs = $entity->purchases;
  # need to add way to search through all transactions and get a true statement to not run this every time

  # https://www.perlmonks.org/?node_id=1092020

  my $day_0 = $purchase_rs->search({
    'buyer.purchase_time'
  },
  {
    order_by => { -asc => 'buyer.purchase_time' },
    rows => 1
  });

  my $day_5 = $day_0->clone->add( days => 5 );

  #shopaholic check (5 transactions in 1 day)
  my $shopaholic = 0;

  # TODO need to do quantized stuff here

  $check_day = $day_0->clone;
  while ( $check_day->add(days => 1) < $today )
  {
    my $today_transactions = $purchase_rs->search({
      'buyer.purchase_time'->day => $check_day
    });

    my $today_count = $today_transactions->count;

    if ( $today_count >= 5 )
    {
      $shopaholic = 1;
      last;
    }
  }

  my $transaction_count = $purchase_rs->count;
  my $fair_transaction = $purchase_rs->search({
    'organisation.is_fair' => 1,
  },
  {
    join => { 'buyer' => 'organisation' }
  });

  my $local_transaction = $purchase_rs->search({
    'organisation.is_local' => 1,
  },
  {
    join => { 'buyer' => 'organisation' }
  });

  my $close_transaction = $purchase_rs->search({
    'me.distance' => { '<', 20000 },
  });

  # Not unique names
  my @orgs = $purchase_rs->search({
    'organisation.id',
    'organisation.name',
  },
  {
    join => { 'buyer' => 'organisation' },
    distinct => 1,
  });

  my $org_completionist_count = 0;

  # Need to add all org medals to each organisation, in loop maybe?
  my $organisation_medals_test = {
    for $org (@orgs)
    {
      my $org_transactions = $purchase_rs->search({
        'organisation.id' => $org.id,
      },
      {
        join => { 'buyer' => 'organisation' }
      });

      my $loyal_customer = $org_transactions->count;

      my $devoted_customer = 0;

      my $org_day_0 = $org_transactions->search({
        'buyer.purchase_time'
      },
      {
        order_by => { -asc => 'buyer.purchase_time' },
        rows => 1
      });

      #Devoted Customer -start
      my $org_check_day_start = $org_day_0->clone;
      my $devoted_customer = 0;

      # TODO need to do quantized stuff here

      while ( $org_check_day_start->add(days => 1) < $today )
      {
        my $org_check_day_end = $org_check_day_start->clone->add( days => 7 );
        my $week_transactions = $purchase_rs->search({
          'buyer.purchase_time'->day => { -between => [ $org_check_day_start, $org_check_day_end ] }
        });

        my $week_count = $week_transactions->count;

        if ( $week_count >= 5 )
        {
          $devoted_customer = 1;
          last;
        }
      }
      #Devoted Customer -end

      #Repeat Customer -start
      my $repeat_customer_check_day = $org_day_0->clone;
      my $repeat_customer = 0;

      # TODO need to do quantized stuff here
      while ( $repeat_customer_check_day->add(days => 1) < $today )
      {
        my $today_transactions = $purchase_rs->search({
          'buyer.purchase_time'->day => $repeat_customer_check_day
        });

        my $today_count = $today_transactions->count;

        if ( $today_count >= 2 )
        {
          $repeat_customer = 1;
          last;
        }
      }
      #Repeat Customer -end

      #Completionist -start
      if( $loyal_customer >= 50 && $devoted_customer == 1 && $repeat_customer == 1)
      {
        $org_completionist_count++;
      }
      #Completionist -end

      $org.name => {
        # Visit org x times
        LoyalCustomer => {
          2 => { awarded => false, awarded_at => false, threshold => 2, points => 20, multiplier => 1, },
          5 => { awarded => false, awarded_at => false, threshold => 5, points => 50, multiplier => 1, },
          10 => { awarded => false, awarded_at => false, threshold => 10, points => 100, multiplier => 1, },
          25 => { awarded => false, awarded_at => false, threshold => 25, points => 250, multiplier => 1, },
          50 => { awarded => false, awarded_at => false, threshold => 50, points => 500, multiplier => 1, },
          total => $loyal_customer,
        },
        # visit org 5 times in one week
        DevotedCustomer => {
          1 => { awarded => false, awarded_at => false, threshold => 1, points => 50, multiplier => 1, },
          total => $devoted_customer,
        },
        # visit org twice in one day
        RepeatCustomer => {
          2 => { awarded => false, awarded_at => false, threshold => 5, points => 20, multiplier => 1, },
          total => $repeat_customer,
        },
      },
    }
  };

  my $global_medals_test = {
    # Total number of transations
    KeenShopper => {
      1 => { awarded => false, awarded_at => false, threshold => 1, points => 10, },
      5 => { awarded => false, awarded_at => false, threshold => 5, points => 50, },
      25 => { awarded => false, awarded_at => false, threshold => 25, points => 250, },
      100 => { awarded => false, awarded_at => false, threshold => 100, points => 1000, },
      1000 => { awarded => false, awarded_at => false, threshold => 1000, points => 10000, },
      total => $transaction_count,
    },
    # Total number of 'fair' transactions
    FairTradesman => {
      1 => { awarded => false, awarded_at => false, threshold => 1, points => 10, },
      5 => { awarded => false, awarded_at => false, threshold => 5, points => 50, },
      25 => { awarded => false, awarded_at => false, threshold => 25, points => 250, },
      100 => { awarded => false, awarded_at => false, threshold => 100, points => 1000, },
      1000 => { awarded => false, awarded_at => false, threshold => 1000, points => 10000, },
      total => $fair_transaction->count,
    },
    # Total number of 'local' transactions
    LocalLoyalist => {
      1 => { awarded => false, awarded_at => false, threshold => 1, points => 10, },
      5 => { awarded => false, awarded_at => false, threshold => 5, points => 50, },
      25 => { awarded => false, awarded_at => false, threshold => 25, points => 250, },
      100 => { awarded => false, awarded_at => false, threshold => 100, points => 1000, },
      1000 => { awarded => false, awarded_at => false, threshold => 1000, points => 10000, },
      total => $local_transaction->count,
    },
    # Total number of 'close' transactions
    Agoraphobic => {
      1 => { awarded => false, awarded_at => false, threshold => 1, points => 10, },
      5 => { awarded => false, awarded_at => false, threshold => 5, points => 50, },
      25 => { awarded => false, awarded_at => false, threshold => 25, points => 250, },
      100 => { awarded => false, awarded_at => false, threshold => 100, points => 1000, },
      1000 => { awarded => false, awarded_at => false, threshold => 1000, points => 10000, },
      total => $close_transaction->count,
    },
    # Visit 5 shops in one day
    Shopaholic => {
      1 => { awarded => false, awarded_at => false, threshold => 1, points => 250, },
      total => $shopaholic,
    },
    # Earn all medals for an organisation
    Completionist => {
      1 => { awarded => false, awarded_at => false, threshold => 1, points => 500, },
      3 => { awarded => false, awarded_at => false, threshold => 3, points => 1000, },
      10 => { awarded => false, awarded_at => false, threshold => 10, points => 2500, },
      25 => { awarded => false, awarded_at => false, threshold => 25, points => 5000, },
      50 => { awarded => false, awarded_at => false, threshold => 50, points => 15000, },
      total => $org_completionist_count,
    },
  };

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      global => $global_placeholder,
      organisation => $organisation_placeholder,
    }
  );
}

1;
