-- TRAINING CATALOG
CREATE TABLE IF NOT EXISTS trainings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    trainer TEXT,
    duration_hours INTEGER,
    status TEXT DEFAULT 'active', -- active, archived
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE trainings ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_trainings_policy' AND tablename = 'trainings') THEN
    CREATE POLICY tenant_trainings_policy ON trainings USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- TRAINING ASSIGNMENTS
CREATE TABLE IF NOT EXISTS training_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    training_id UUID REFERENCES trainings(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    assigned_date DATE DEFAULT CURRENT_DATE,
    completion_date DATE,
    status TEXT DEFAULT 'assigned', -- assigned, in-progress, completed, failed
    notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE training_assignments ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_training_assignments_policy' AND tablename = 'training_assignments') THEN
    CREATE POLICY tenant_training_assignments_policy ON training_assignments USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- PERFORMANCE REVIEWS
CREATE TABLE IF NOT EXISTS performance_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    reviewer_id UUID REFERENCES employees(id) NOT NULL,
    review_date DATE NOT NULL,
    period_start DATE,
    period_end DATE,
    overall_score NUMERIC(3,2),
    comments TEXT,
    status TEXT DEFAULT 'draft', -- draft, submitted, finalized
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE performance_reviews ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_performance_reviews_policy' AND tablename = 'performance_reviews') THEN
    CREATE POLICY tenant_performance_reviews_policy ON performance_reviews USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- PERFORMANCE GOALS
CREATE TABLE IF NOT EXISTS performance_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    target_date DATE,
    weightage INTEGER DEFAULT 1,
    status TEXT DEFAULT 'active', -- active, achieved, missed, cancelled
    achievement_notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE performance_goals ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_performance_goals_policy' AND tablename = 'performance_goals') THEN
    CREATE POLICY tenant_performance_goals_policy ON performance_goals USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
