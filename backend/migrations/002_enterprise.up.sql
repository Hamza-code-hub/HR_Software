-- ================================
-- 002_enterprise.up.sql
-- Enterprise schema additions
-- ================================

-- DEPARTMENTS
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  name TEXT NOT NULL,
  manager_id UUID REFERENCES employees(id),
  deleted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE (tenant_id, name)
);

CREATE INDEX IF NOT EXISTS idx_departments_tenant ON departments(tenant_id);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_departments_policy' AND tablename = 'departments') THEN
    CREATE POLICY tenant_departments_policy ON departments USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- Add department_id to employees
ALTER TABLE employees ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id);
ALTER TABLE employees ADD COLUMN IF NOT EXISTS basic_salary NUMERIC DEFAULT 0;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS allowances JSONB DEFAULT '{}';
ALTER TABLE employees ADD COLUMN IF NOT EXISTS deductions JSONB DEFAULT '{}';
ALTER TABLE employees ADD COLUMN IF NOT EXISTS employment_type TEXT DEFAULT 'full_time';
ALTER TABLE employees ADD COLUMN IF NOT EXISTS probation_end_date DATE;

-- LEAVE TYPES
CREATE TABLE IF NOT EXISTS leave_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  name TEXT NOT NULL,
  days_per_year INT NOT NULL DEFAULT 0,
  is_paid BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE (tenant_id, name)
);

CREATE INDEX IF NOT EXISTS idx_leave_types_tenant ON leave_types(tenant_id);

ALTER TABLE leave_types ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_leave_types_policy' AND tablename = 'leave_types') THEN
    CREATE POLICY tenant_leave_types_policy ON leave_types USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- LEAVE REQUESTS
CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  employee_id UUID REFERENCES employees(id) NOT NULL,
  leave_type_id UUID REFERENCES leave_types(id) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days_count INT NOT NULL DEFAULT 1,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, rejected
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMP,
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_leave_requests_tenant ON leave_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_employee ON leave_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);

ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_leave_requests_policy' AND tablename = 'leave_requests') THEN
    CREATE POLICY tenant_leave_requests_policy ON leave_requests USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- ANNOUNCEMENTS (useful for admin broadcasts)
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  priority TEXT DEFAULT 'normal', -- low, normal, high, urgent
  created_by UUID REFERENCES users(id),
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_announcements_policy' AND tablename = 'announcements') THEN
    CREATE POLICY tenant_announcements_policy ON announcements USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- Seed default leave types (via function to avoid duplicates)
-- These will be seeded per-tenant via the application layer.

-- Add role constraint comment
COMMENT ON COLUMN tenant_users.role IS 'admin | hr | accounting | employee';
