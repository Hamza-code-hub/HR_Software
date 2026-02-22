-- EXIT CLEARANCE CHECKLIST
CREATE TABLE IF NOT EXISTS exit_clearance_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    resignation_id UUID REFERENCES resignations(id) NOT NULL,
    department TEXT NOT NULL, -- IT, Finance, Admin, etc.
    item_name TEXT NOT NULL, -- e.g., "Returned Laptop", "ID Card", "Utility Bills"
    status TEXT DEFAULT 'pending', -- pending, cleared, na
    cleared_by_id UUID REFERENCES users(id),
    cleared_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE exit_clearance_checklists ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_exit_clearance_policy' AND tablename = 'exit_clearance_checklists') THEN
    CREATE POLICY tenant_exit_clearance_policy ON exit_clearance_checklists USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- EXIT INTERVIEWS
CREATE TABLE IF NOT EXISTS exit_interviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    resignation_id UUID REFERENCES resignations(id) NOT NULL UNIQUE,
    interview_date DATE DEFAULT CURRENT_DATE,
    interviewer_id UUID REFERENCES users(id),
    reason_for_leaving TEXT,
    feedback_management TEXT,
    feedback_culture TEXT,
    recommend_company BOOLEAN DEFAULT true,
    additional_comments TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE exit_interviews ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_exit_interviews_policy' AND tablename = 'exit_interviews') THEN
    CREATE POLICY tenant_exit_interviews_policy ON exit_interviews USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
