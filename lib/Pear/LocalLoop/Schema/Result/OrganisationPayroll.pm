package Pear::LocalLoop::Schema::Result::OrganisationPayroll;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    qw/
      InflateColumn::DateTime
      TimeStamp
      /
);

__PACKAGE__->table("organisation_payroll");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "org_id" => {
        data_type      => 'integer',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
    "submitted_at" => {
        data_type     => "datetime",
        is_nullable   => 0,
        set_on_create => 1,
    },
    "entry_period" => {
        data_type   => "datetime",
        is_nullable => 0,
    },
    "employee_amount" => {
        data_type   => "integer",
        is_nullable => 0,
    },
    "local_employee_amount" => {
        data_type   => "integer",
        is_nullable => 0,
    },
    "gross_payroll" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "payroll_income_tax" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "payroll_employee_ni" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "payroll_employer_ni" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "payroll_total_pension" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
    "payroll_other_benefit" => {
        data_type   => "numeric",
        size        => [ 100, 0 ],
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( "organisation",
    "Pear::LocalLoop::Schema::Result::Organisation", "org_id", );

1;
