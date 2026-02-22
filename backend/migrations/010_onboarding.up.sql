-- OFFER LETTERS
CREATE TABLE IF NOT EXISTS offer_letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    candidate_id UUID REFERENCES candidates(id) NOT NULL,
    job_id UUID REFERENCES job_postings(id) NOT NULL,
    salary_offered NUMERIC NOT NULL,
    joining_date DATE,
    valid_until DATE,
    status TEXT DEFAULT 'draft', -- draft, sent, accepted, declined, expired
    notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE offer_letters ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_offer_letters_policy' AND tablename = 'offer_letters') THEN
    CREATE POLICY tenant_offer_letters_policy ON offer_letters USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- EMPLOYEE CONTRACTS
CREATE TABLE IF NOT EXISTS employee_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    contract_type TEXT NOT NULL, -- permanent, fixed-term, consultant
    start_date DATE NOT NULL,
    end_date DATE,
    status TEXT DEFAULT 'active', -- active, expired, terminated, renewed
    document_url TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE employee_contracts ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_employee_contracts_policy' AND tablename = 'employee_contracts') THEN
    CREATE POLICY tenant_employee_contracts_policy ON employee_contracts USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
