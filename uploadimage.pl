#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo:Upload;

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
  $c->render(text => 'db entry data upload failed.');
};

# Uploading Image
post '/upload' => sub {
  my $c = shift;

  my $upload = Mojo::Upload->new;
  say $upload->filename;
  $upload->move_to('images/' . $upload->filename);

};
app->start;
