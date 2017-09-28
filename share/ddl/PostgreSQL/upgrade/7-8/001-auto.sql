-- Convert schema 'share/ddl/_source/deploy/7/001-auto.yml' to 'share/ddl/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "organisation_payroll" (
  "id" serial NOT NULL,
  "org_id" integer NOT NULL,
  "submitted_at" timestamp NOT NULL,
  "entry_period" timestamp NOT NULL,
  "employee_amount" integer NOT NULL,
  "local_employee_amount" integer NOT NULL,
  "gross_payroll" numeric(100,0) NOT NULL,
  "payroll_income_tax" numeric(100,0) NOT NULL,
  "payroll_employee_ni" numeric(100,0) NOT NULL,
  "payroll_employer_ni" numeric(100,0) NOT NULL,
  "payroll_total_pension" numeric(100,0) NOT NULL,
  "payroll_other_benefit" numeric(100,0) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "organisation_payroll_idx_org_id" on "organisation_payroll" ("org_id");

;
ALTER TABLE "organisation_payroll" ADD CONSTRAINT "organisation_payroll_fk_org_id" FOREIGN KEY ("org_id")
  REFERENCES "organisations" ("id") DEFERRABLE;

;

COMMIT;

