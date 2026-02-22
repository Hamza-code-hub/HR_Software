-- PROJECTS
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    name TEXT NOT NULL,
    client_name TEXT,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'active', -- active, completed, on-hold
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_projects_policy' AND tablename = 'projects') THEN
    CREATE POLICY tenant_projects_policy ON projects USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- OVERTIME REQUESTS
CREATE TABLE IF NOT EXISTS overtime_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    date DATE NOT NULL,
    hours NUMERIC(4,2) NOT NULL,
    reason TEXT,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    approved_by_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE overtime_requests ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_overtime_requests_policy' AND tablename = 'overtime_requests') THEN
    CREATE POLICY tenant_overtime_requests_policy ON overtime_requests USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
