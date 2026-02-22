-- ================================
-- 003_asset_management.up.sql
-- Asset Management additions
-- ================================

-- ASSETS
CREATE TABLE IF NOT EXISTS assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- laptop, monitor, keyboard, etc.
    serial_number TEXT,
    purchase_date DATE,
    status TEXT DEFAULT 'available', -- available, assigned, maintenance, retired
    condition TEXT DEFAULT 'new', -- new, good, fair, poor
    notes TEXT,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assets_tenant ON assets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_assets_status ON assets(status);

ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_assets_policy' AND tablename = 'assets') THEN
    CREATE POLICY tenant_assets_policy ON assets USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- ASSET ASSIGNMENTS
CREATE TABLE IF NOT EXISTS asset_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    asset_id UUID REFERENCES assets(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    assigned_date DATE NOT NULL,
    returned_date DATE,
    condition_out TEXT,
    condition_in TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_asset_assignments_tenant ON asset_assignments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_asset_assignments_asset ON asset_assignments(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_assignments_employee ON asset_assignments(employee_id);

ALTER TABLE asset_assignments ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_asset_assignments_policy' AND tablename = 'asset_assignments') THEN
    CREATE POLICY tenant_asset_assignments_policy ON asset_assignments USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;

-- ASSET REQUESTS
CREATE TABLE IF NOT EXISTS asset_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    employee_id UUID REFERENCES employees(id) NOT NULL,
    requested_type TEXT NOT NULL,
    justification TEXT,
    status TEXT DEFAULT 'pending', -- pending, approved, fulfilled, rejected
    priority TEXT DEFAULT 'normal', -- low, normal, high, urgent
    notes TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_asset_requests_tenant ON asset_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_asset_requests_employee ON asset_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_asset_requests_status ON asset_requests(status);

ALTER TABLE asset_requests ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'tenant_asset_requests_policy' AND tablename = 'asset_requests') THEN
    CREATE POLICY tenant_asset_requests_policy ON asset_requests USING (tenant_id = current_setting('app.tenant_id', true)::UUID);
  END IF;
END $$;
