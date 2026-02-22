-- SHIFTS
CREATE TABLE IF NOT EXISTS shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    name TEXT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    grace_period_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_shifts_policy' AND tablename = 'shifts') THEN
    CREATE POLICY tenant_shifts_policy ON shifts USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- EMPLOYEE SHIFTS
CREATE TABLE IF NOT EXISTS employee_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    shift_id UUID REFERENCES shifts(id) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL means ongoing
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE employee_shifts ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_employee_shifts_policy' AND tablename = 'employee_shifts') THEN
    CREATE POLICY tenant_employee_shifts_policy ON employee_shifts USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- TIMESHEETS
CREATE TABLE IF NOT EXISTS timesheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    date DATE NOT NULL,
    project_id UUID, -- Optional, can link to a project table if needed later
    task_description TEXT,
    hours_worked NUMERIC(5,2) NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE timesheets ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_timesheets_policy' AND tablename = 'timesheets') THEN
    CREATE POLICY tenant_timesheets_policy ON timesheets USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
