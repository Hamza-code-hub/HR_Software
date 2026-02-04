-- Employee salary fields for payroll snapshot (MVP)
ALTER TABLE employees
  ADD COLUMN IF NOT EXISTS basic_salary NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS allowances JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS deductions JSONB DEFAULT '{}';
