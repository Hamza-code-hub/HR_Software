-- JOB POSTINGS
CREATE TABLE IF NOT EXISTS job_postings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    title TEXT NOT NULL,
    department TEXT,
    location TEXT,
    employment_type TEXT, -- Full-time, Part-time, Contract
    description TEXT,
    requirements TEXT,
    status TEXT DEFAULT 'open', -- open, closed, draft
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE job_postings ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_job_postings_policy' AND tablename = 'job_postings') THEN
    CREATE POLICY tenant_job_postings_policy ON job_postings USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- CANDIDATES
CREATE TABLE IF NOT EXISTS candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    job_id UUID REFERENCES job_postings(id),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    resume_url TEXT,
    status TEXT DEFAULT 'new', -- new, screened, interviewed, offer, hired, rejected
    source TEXT,
    applied_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_candidates_policy' AND tablename = 'candidates') THEN
    CREATE POLICY tenant_candidates_policy ON candidates USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- INTERVIEWS
CREATE TABLE IF NOT EXISTS interviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    candidate_id UUID REFERENCES candidates(id) NOT NULL,
    interviewer_id UUID REFERENCES employees(id),
    scheduled_at TIMESTAMP NOT NULL,
    duration_minutes INT DEFAULT 30,
    location TEXT,
    meeting_link TEXT,
    status TEXT DEFAULT 'scheduled', -- scheduled, completed, cancelled
    feedback TEXT,
    rating INT, -- 1-5
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE interviews ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_interviews_policy' AND tablename = 'interviews') THEN
    CREATE POLICY tenant_interviews_policy ON interviews USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
