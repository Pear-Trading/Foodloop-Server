use utf8;
package Pear::LocalLoop::Schema::Result::PendingTransaction;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( qw/
  InflateColumn::DateTime
  InflateColumn::FS
/);

__PACKAGE__->table("PendingTransactions");

__PACKAGE__->add_columns(
  "pendingtransactionid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "buyeruserid_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pendingsellerorganisationid_fk",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "valuemicrocurrency",
  { data_type => "integer", is_nullable => 0 },
  "proof_image",
  {
    data_type => "text",
    is_nullable => 0,
  },
  "timedatesubmitted",
  { data_type => "datetime", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("pendingtransactionid");

__PACKAGE__->belongs_to(
  "buyeruserid_fk",
  "Pear::LocalLoop::Schema::Result::User",
  { id => "buyeruserid_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "pendingsellerorganisationid_fk",
  "Pear::LocalLoop::Schema::Result::PendingOrganisation",
  { id => "pendingsellerorganisationid_fk" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
