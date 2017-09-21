-- Convert schema 'share/ddl/_source/deploy/7/001-auto.yml' to 'share/ddl/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE organisation_payroll (
  id INTEGER PRIMARY KEY NOT NULL,
  org_id integer NOT NULL,
  submitted_at datetime NOT NULL,
  entry_period datetime NOT NULL,
  employee_amount integer NOT NULL,
  local_employee_amount integer NOT NULL,
  gross_payroll numeric(100,0) NOT NULL,
  payroll_income_tax numeric(100,0) NOT NULL,
  payroll_employee_ni numeric(100,0) NOT NULL,
  payroll_employer_ni numeric(100,0) NOT NULL,
  payroll_total_pension numeric(100,0) NOT NULL,
  payroll_other_benefit numeric(100,0) NOT NULL,
  FOREIGN KEY (org_id) REFERENCES organisations(id)
);

;
CREATE INDEX organisation_payroll_idx_org_id ON organisation_payroll (org_id);

;

COMMIT;

