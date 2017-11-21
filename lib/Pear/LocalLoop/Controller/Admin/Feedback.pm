package Pear::LocalLoop::Controller::Admin::Feedback;
use Mojo::Base 'Mojolicious::Controller';

has result_set => sub {
  my $c = shift;
  return $c->schema->resultset('Feedback');
};

sub index {
  my $c = shift;

  my $feedback_rs = $c->result_set->search(
    undef, 
    {
      page => $c->param('page') || 1,
      rows => 12,
      order_by => { -desc => 'submitted_at' },
    },
  );
  $c->stash( feedback_rs => $feedback_rs );
}

sub read {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $feedback = $c->result_set->find($id) ) {
    $c->stash( feedback => $feedback );
  } else {
    $c->flash( error => 'No Feedback found' );
    $c->redirect_to( '/admin/feedback' );
  }
}

sub actioned {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $feedback = $c->result_set->find($id) ) {
    $feedback->actioned( ! $feedback->actioned );
    $feedback->update;
    $c->redirect_to( '/admin/feedback/' . $id );
  } else {
    $c->flash( error => 'No Feedback found' );
    $c->redirect_to( '/admin/feedback' );
  }
}

1;
