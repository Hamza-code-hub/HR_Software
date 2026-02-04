-- TENANTS
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  subdomain TEXT UNIQUE,
  subscription_tier TEXT,
  subscription_status TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- USERS (global, no tenant_id)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

-- TENANT USERS
CREATE TABLE IF NOT EXISTS tenant_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  user_id UUID REFERENCES users(id),
  role TEXT,
  UNIQUE (tenant_id, user_id)
);

-- EMPLOYEES
CREATE TABLE IF NOT EXISTS employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  user_id UUID REFERENCES users(id),
  employee_code TEXT,
  name TEXT NOT NULL,
  email TEXT,
  cnic TEXT,
  phone TEXT,
  designation TEXT,
  joining_date DATE,
  status TEXT DEFAULT 'active',
  deleted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_employees_tenant_id ON employees(tenant_id);
CREATE INDEX idx_employees_deleted_at ON employees(deleted_at) WHERE deleted_at IS NULL;

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_employee_policy ON employees
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);

-- ATTENDANCE
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  employee_id UUID REFERENCES employees(id) NOT NULL,
  date DATE NOT NULL,
  check_in TIMESTAMP,
  check_out TIMESTAMP,
  total_hours NUMERIC(5,2),
  status TEXT,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_attendance_tenant_date ON attendance(tenant_id, date);
CREATE UNIQUE INDEX idx_attendance_tenant_employee_date ON attendance(tenant_id, employee_id, date);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_attendance_policy ON attendance
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);

-- PAYROLL RUN
CREATE TABLE IF NOT EXISTS payroll_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  month INT NOT NULL,
  year INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT now()
);

CREATE UNIQUE INDEX idx_payroll_run_tenant_month_year ON payroll_runs(tenant_id, month, year);

ALTER TABLE payroll_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_payroll_runs_policy ON payroll_runs
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);

-- PAYSLIPS
CREATE TABLE IF NOT EXISTS payslips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  payroll_run_id UUID REFERENCES payroll_runs(id) NOT NULL,
  employee_id UUID REFERENCES employees(id) NOT NULL,
  basic_salary NUMERIC NOT NULL DEFAULT 0,
  allowances JSONB DEFAULT '{}',
  deductions JSONB DEFAULT '{}',
  gross_salary NUMERIC NOT NULL DEFAULT 0,
  net_salary NUMERIC NOT NULL DEFAULT 0,
  tax NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_payslips_tenant_run ON payslips(tenant_id, payroll_run_id);

ALTER TABLE payslips ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_payslips_policy ON payslips
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);

-- ACCOUNTS
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  balance NUMERIC DEFAULT 0,
  deleted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_accounts_tenant_id ON accounts(tenant_id);

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_accounts_policy ON accounts
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);

-- JOURNAL
CREATE TABLE IF NOT EXISTS journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_journal_entries_tenant_date ON journal_entries(tenant_id, date);

ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_journal_entries_policy ON journal_entries
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);

CREATE TABLE IF NOT EXISTS journal_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  journal_entry_id UUID REFERENCES journal_entries(id) NOT NULL,
  account_id UUID REFERENCES accounts(id) NOT NULL,
  debit NUMERIC DEFAULT 0,
  credit NUMERIC DEFAULT 0,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_journal_lines_entry ON journal_lines(journal_entry_id);

ALTER TABLE journal_lines ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_journal_lines_policy ON journal_lines
  USING (tenant_id = current_setting('app.tenant_id', true)::UUID);

-- Refresh tokens for JWT
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
