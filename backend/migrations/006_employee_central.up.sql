-- EMPLOYEE DOCUMENTS
CREATE TABLE IF NOT EXISTS employee_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    document_name TEXT NOT NULL,
    document_type TEXT, -- ID Card, Contract, Degree, etc.
    document_url TEXT NOT NULL,
    upload_date TIMESTAMP DEFAULT now(),
    expiry_date DATE,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE employee_documents ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_employee_documents_policy' AND tablename = 'employee_documents') THEN
    CREATE POLICY tenant_employee_documents_policy ON employee_documents USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- PROBATION TRACKING
CREATE TABLE IF NOT EXISTS probation_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT DEFAULT 'active', -- active, extended, completed, terminated
    review_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE probation_tracking ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_probation_tracking_policy' AND tablename = 'probation_tracking') THEN
    CREATE POLICY tenant_probation_tracking_policy ON probation_tracking USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- EMPLOYEE PROMOTIONS & TRANSFERS
CREATE TABLE IF NOT EXISTS employee_promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    previous_designation TEXT,
    new_designation TEXT,
    previous_salary NUMERIC,
    new_salary NUMERIC,
    type TEXT, -- Promotion, Transfer, Both
    effective_date DATE NOT NULL,
    notes TEXT,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE employee_promotions ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_employee_promotions_policy' AND tablename = 'employee_promotions') THEN
    CREATE POLICY tenant_employee_promotions_policy ON employee_promotions USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
