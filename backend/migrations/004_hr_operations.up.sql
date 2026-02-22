-- ================================
-- 004_hr_operations.up.sql
-- Hiring Requirements and Resignations
-- ================================

-- HIRING REQUIREMENTS
CREATE TABLE IF NOT EXISTS hiring_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    requested_by_id UUID REFERENCES employees(id) NOT NULL,
    department_id UUID REFERENCES departments(id) NOT NULL,
    job_title TEXT NOT NULL,
    number_of_positions INTEGER DEFAULT 1,
    priority TEXT DEFAULT 'normal', -- low, normal, high, urgent
    status TEXT DEFAULT 'pending', -- pending, approved, rejected, fulfilled
    justification TEXT,
    requested_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hiring_requirements_tenant ON hiring_requirements(tenant_id);
CREATE INDEX IF NOT EXISTS idx_hiring_requirements_dept ON hiring_requirements(department_id);
CREATE INDEX IF NOT EXISTS idx_hiring_requirements_status ON hiring_requirements(status);

ALTER TABLE hiring_requirements ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_hiring_requirements_policy' AND tablename = 'hiring_requirements') THEN
    CREATE POLICY tenant_hiring_requirements_policy ON hiring_requirements USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- RESIGNATIONS
CREATE TABLE IF NOT EXISTS resignations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    resignation_date DATE DEFAULT CURRENT_DATE,
    last_working_day DATE,
    reason TEXT,
    status TEXT DEFAULT 'pending', -- pending, accepted, rejected, completed
    exit_clearance_status TEXT DEFAULT 'pending', -- pending, in_progress, cleared
    notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_resignations_tenant ON resignations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_resignations_employee ON resignations(employee_id);
CREATE INDEX IF NOT EXISTS idx_resignations_status ON resignations(status);

ALTER TABLE resignations ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_resignations_policy' AND tablename = 'resignations') THEN
    CREATE POLICY tenant_resignations_policy ON resignations USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
