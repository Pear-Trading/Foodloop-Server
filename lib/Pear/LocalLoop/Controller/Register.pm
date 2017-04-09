package Pear::LocalLoop::Controller::Register;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;

  my $agerange_rs = $c->schema->resultset('AgeRange');
  $agerange_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $c->stash( ageranges => [ $agerange_rs->all ] );
}

sub register {
  my $c = shift;
  my $validation = $c->validation;

  $validation->required('name', 'trim');
  $validation->required('email')->email;
  $validation->required('password')->equal_to('password2');
  $validation->required('postcode')->postcode;

  my $token_rs = $c->schema->resultset('AccountToken')->search_rs({used => 0});
  $validation->required('token')->in_resultset('accounttokenname', $token_rs);

  my $age_rs = $c->schema->resultset('AgeRange');
  $validation->required('agerange')->in_resultset('agerangeid', $age_rs);

  use Devel::Dwarn;
  Dwarn $validation;
  $c->redirect_to('/register');
}

1;
