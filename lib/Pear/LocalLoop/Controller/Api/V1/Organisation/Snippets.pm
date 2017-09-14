package Pear::LocalLoop::Controller::Api::V1::Organisation::Snippets;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

  my $entity = $c->stash->{api_user}->entity;
  my $data = {
    this_month_sales_count => 0,
    this_month_sales_total => 0,
    this_month_purchases_count => 0,
    this_month_purchases_total => 0,
    this_week_sales_count => 0,
    this_week_sales_total => 0,
    this_week_purchases_count => 0,
    this_week_purchases_total => 0,
    today_sales_count => 0,
    today_sales_total => 0,
    today_purchases_count => 0,
    today_purchases_total => 0,
  };

  my $now = DateTime->now;
  my $today = DateTime->today;
  my $week_ago = $today->clone->subtract( days => 7 );
  my $month_ago = $today->clone->subtract( days => 30 );

  my $today_sales = $entity->sales->search_between( $today, $now );
  $data->{ today_sales_count } = $today_sales->count;
  $data->{ today_sales_total } = $today_sales->get_column('value')->sum || 0;
  $data->{ today_sales_total } /= 100000;

  my $week_sales = $entity->sales->search_between( $week_ago, $today );
  $data->{ this_week_sales_count } = $week_sales->count;
  $data->{ this_week_sales_total } = $week_sales->get_column('value')->sum || 0;
  $data->{ this_week_sales_total } /= 100000;

  my $month_sales = $entity->sales->search_between( $month_ago, $today );
  $data->{ this_month_sales_count } = $month_sales->count;
  $data->{ this_month_sales_total } = $month_sales->get_column('value')->sum || 0;
  $data->{ this_month_sales_total } /= 100000;

  my $today_purchases = $entity->purchases->search_between( $today, $now );
  $data->{ today_purchases_count } = $today_purchases->count;
  $data->{ today_purchases_total } = $today_purchases->get_column('value')->sum || 0;
  $data->{ today_purchases_total } /= 100000;

  my $week_purchases = $entity->purchases->search_between( $week_ago, $today );
  $data->{ this_week_purchases_count } = $week_purchases->count;
  $data->{ this_week_purchases_total } = $week_purchases->get_column('value')->sum || 0;
  $data->{ this_week_purchases_total } /= 100000;

  my $month_purchases = $entity->purchases->search_between( $month_ago, $today );
  $data->{ this_month_purchases_count } = $month_purchases->count;
  $data->{ this_month_purchases_total } = $month_purchases->get_column('value')->sum || 0;
  $data->{ this_month_purchases_total } /= 100000;

  return $c->render(
    json => {
      success => Mojo::JSON->true,
      snippets => $data,
    }
  );

}

1;
