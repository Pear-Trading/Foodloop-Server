#! perl

use strict;
use warnings;

use DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader({ naming => 'v7' }, sub {
  my $schema = shift;

  my $user_rs          = $schema->resultset('UsersTemp');
  my $customer_rs      = $schema->resultset('CustomersTemp');
  my $organisation_rs  = $schema->resultset('OrganisationsTemp');
  my $transaction_rs   = $schema->resultset('TransactionsTemp');
  my $pending_org_rs   = $schema->resultset('PendingOrganisation');
  my $pending_trans_rs = $schema->resultset('PendingTransaction');
  my $feedback_rs      = $schema->resultset('FeedbackTemp');
  my $session_token_rs = $schema->resultset('SessionTokensTemp');

  # Lookups used for converting transactions
  my $org_lookup = {};
  my $user_lookup = {};

  # First migrate all customers, organisations, and pending organisations across to the entity table.
  for my $customer_result ( $customer_rs->all ) {
    my $user_result   = $user_rs->find({ customer_id => $customer_result->id });
    my $administrator = $schema->resultset('Administrator')->find({ user_id => $user_result->id });
    my $new_entity    = $schema->resultset('Entity')->create({ type => 'customer' });

    my $new_customer = $schema->resultset('Customer')->create({
      entity_id     => $new_entity->id,
      display_name  => $customer_result->display_name,
      full_name     => $customer_result->full_name,
      year_of_birth => $customer_result->year_of_birth,
      postcode      => $customer_result->postcode,
    });

    # In the old system, all customers were users
    my $new_user = $schema->resultset('User')->create({
      entity_id => $new_entity->id,
      email     => $user_result->email,
      join_date => $user_result->join_date,
      password  => $user_result->password,
      is_admin  => defined $administrator ? 1 : 0,
    });
    $user_lookup->{$user_result->id} = $new_entity->id;
  }

  for my $organisation_result ( $organisation_rs->all ) {
    my $user_result = $user_rs->find({ organisation_id => $organisation_result->id });
    my $new_entity = $schema->resultset('Entity')->create({ type => 'organisation' });

    my $org = $schema->resultset('Organisation')->create({
      entity_id   => $new_entity->id,
      name        => $organisation_result->name,
      street_name => $organisation_result->street_name,
      town        => $organisation_result->town,
      postcode    => $organisation_result->postcode,
    });

    # In the old system, not all organisations were users - but could have still been an admin?
    if ( defined $user_result ) {
      my $administrator = $schema->resultset('Administrator')->find({ user_id => $user_result->id });
      my $new_user = $schema->resultset('User')->create({
        entity_id => $new_entity->id,
        email     => $user_result->email,
        join_date => $user_result->join_date,
        password  => $user_result->password,
        is_admin  => defined $administrator ? 1 : 0,
      });
      $user_lookup->{$user_result->id} = $new_entity->id;
    }
    $org_lookup->{$organisation_result->id} = $new_entity->id;
  }

  for my $transaction_result ( $transaction_rs->all ) {
    my $new_transaction = $schema->resultset('Transaction')->create({
      buyer_id      => $user_lookup->{ $transaction_result->buyer_id },
      seller_id     => $org_lookup->{ $transaction_result->seller_id },
      value         => $transaction_result->value,
      proof_image   => $transaction_result->proof_image,
      submitted_at  => $transaction_result->submitted_at,
      purchase_time => $transaction_result->purchase_time,
    });
  }

  for my $pending_result ( $pending_org_rs->all ) {
    my $entity = $schema->resultset('Entity')->create({ type => 'organisation' });
    my $org = $schema->resultset('Organisation')->create({
      entity_id       => $entity->id,
      name            => $pending_result->name,
      street_name     => $pending_result->street_name,
      town            => $pending_result->town,
      postcode        => $pending_result->postcode,
      submitted_by_id => $user_lookup->{ $pending_result->submitted_by_id },
      pending => 1,
    });
    my $pending_trans_set_rs = $pending_trans_rs->search({
      seller_id => $pending_result->id,
    });
    for my $trans_result ( $pending_trans_set_rs->all ) {
      $schema->resultset('Transaction')->create({
        buyer_id      => $user_lookup->{ $trans_result->buyer_id },
        seller_id     => $entity->id,
        value         => $trans_result->value,
        proof_image   => $trans_result->proof_image,
        submitted_at  => $trans_result->submitted_at,
        purchase_time => $trans_result->purchase_time,
      });
    }
  }

  for my $session_token ( $session_token_rs->all ) {
    $schema->resultset('SessionToken')->create({
      token   => $session_token->token,
      user_id => $user_lookup->{ $session_token->user_id },
    });
  }

  for my $feedback_result ( $feedback_rs->all ) {
    $schema->resultset('Feedback')->create({
      user_id        => $user_lookup->{ $feedback_result->user_id },
      submitted_at   => $feedback_result->submitted_at,
      feedbacktext   => $feedback_result->feedbacktext,
      app_name       => $feedback_result->app_name,
      package_name   => $feedback_result->package_name,
      version_code   => $feedback_result->version_code,
      version_number => $feedback_result->version_number,
    });
  }
});
