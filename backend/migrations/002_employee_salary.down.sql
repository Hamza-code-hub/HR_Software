ALTER TABLE employees
  DROP COLUMN IF EXISTS basic_salary,
  DROP COLUMN IF EXISTS allowances,
  DROP COLUMN IF EXISTS deductions;
