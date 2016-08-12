#!/usr/bin/env perl
use Mojolicious::Lite;

# /?user=sebastian&pass=secr3t
any '/' => sub {
  my $c = shift;

  # Query parameters
  my $user = $c->param('user') || '';
  my $company = $c->param('company') || '';
  my $currency = $c->param('currency') || '';
  print "$user $company $currency\n";
  use Devel::Dwarn;
  Dwarn $c->req;
  # Failed
  $c->render(text => 'upload failed.');
};

app->start;
