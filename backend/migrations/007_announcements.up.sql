-- ANNOUNCEMENTS
CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    posted_by_id UUID REFERENCES users(id) NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    priority TEXT DEFAULT 'normal', -- normal, high, urgent
    category TEXT DEFAULT 'general', -- general, event, policy, holiday
    target_audience TEXT DEFAULT 'all', -- all, department:<id>, employee:<id>
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_announcements_policy' AND tablename = 'announcements') THEN
    CREATE POLICY tenant_announcements_policy ON announcements USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
