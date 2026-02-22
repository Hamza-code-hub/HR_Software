package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Asset struct {
	ID           uuid.UUID  `json:"id"`
	TenantID     uuid.UUID  `json:"tenant_id"`
	Name         string     `json:"name"`
	Type         string     `json:"type"`
	SerialNumber *string    `json:"serial_number"`
	PurchaseDate *time.Time `json:"purchase_date"`
	Status       string     `json:"status"`
	Condition    string     `json:"condition"`
	Notes        *string    `json:"notes"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

type AssetAssignment struct {
	ID           uuid.UUID  `json:"id"`
	TenantID     uuid.UUID  `json:"tenant_id"`
	AssetID      uuid.UUID  `json:"asset_id"`
	EmployeeID   uuid.UUID  `json:"employee_id"`
	AssignedDate time.Time  `json:"assigned_date"`
	ReturnedDate *time.Time `json:"returned_date"`
	ConditionOut *string    `json:"condition_out"`
	ConditionIn  *string    `json:"condition_in"`
	Notes        *string    `json:"notes"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
	// Additional joins for frontend display
	AssetName    string `json:"asset_name,omitempty"`
	EmployeeName string `json:"employee_name,omitempty"`
}

type AssetRequest struct {
	ID            uuid.UUID `json:"id"`
	TenantID      uuid.UUID `json:"tenant_id"`
	EmployeeID    uuid.UUID `json:"employee_id"`
	RequestedType string    `json:"requested_type"`
	Justification *string   `json:"justification"`
	Status        string    `json:"status"`
	Priority      string    `json:"priority"`
	Notes         *string   `json:"notes"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
	// Additional joins for frontend display
	EmployeeName string `json:"employee_name,omitempty"`
}

// ---------------------------------------------------------
// ASSETS
// ---------------------------------------------------------

func ListAssets(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Asset, error) {
	var list []Asset
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT id, tenant_id, name, type, serial_number, purchase_date, status, condition, notes, created_at, updated_at
			 FROM assets WHERE deleted_at IS NULL ORDER BY name ASC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var a Asset
			if err := rows.Scan(&a.ID, &a.TenantID, &a.Name, &a.Type, &a.SerialNumber, &a.PurchaseDate, &a.Status, &a.Condition, &a.Notes, &a.CreatedAt, &a.UpdatedAt); err != nil {
				return err
			}
			list = append(list, a)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func CreateAsset(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, asset *Asset) (*Asset, error) {
	var created Asset
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO assets (tenant_id, name, type, serial_number, purchase_date, status, condition, notes)
			 VALUES ($1, $2, $3, $4, $5, COALESCE($6, 'available'), COALESCE($7, 'new'), $8)
			 RETURNING id, tenant_id, name, type, serial_number, purchase_date, status, condition, notes, created_at, updated_at`,
			tenantID, asset.Name, asset.Type, asset.SerialNumber, asset.PurchaseDate, asset.Status, asset.Condition, asset.Notes,
		).Scan(&created.ID, &created.TenantID, &created.Name, &created.Type, &created.SerialNumber, &created.PurchaseDate, &created.Status, &created.Condition, &created.Notes, &created.CreatedAt, &created.UpdatedAt)
	})
	if err != nil {
		return nil, err
	}
	return &created, nil
}

func UpdateAsset(ctx context.Context, pool *pgxpool.Pool, tenantID string, id string, asset *Asset) (*Asset, error) {
	var updated Asset
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`UPDATE assets
			 SET name = $1, type = $2, serial_number = $3, purchase_date = $4, status = $5, condition = $6, notes = $7, updated_at = now()
			 WHERE id = $8 AND deleted_at IS NULL
			 RETURNING id, tenant_id, name, type, serial_number, purchase_date, status, condition, notes, created_at, updated_at`,
			asset.Name, asset.Type, asset.SerialNumber, asset.PurchaseDate, asset.Status, asset.Condition, asset.Notes, id,
		).Scan(&updated.ID, &updated.TenantID, &updated.Name, &updated.Type, &updated.SerialNumber, &updated.PurchaseDate, &updated.Status, &updated.Condition, &updated.Notes, &updated.CreatedAt, &updated.UpdatedAt)
	})
	if err != nil {
		return nil, err
	}
	return &updated, nil
}

func DeleteAsset(ctx context.Context, pool *pgxpool.Pool, tenantID string, id string) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE assets SET deleted_at = now() WHERE id = $1`, id)
		return err
	})
}

// ---------------------------------------------------------
// ASSET ASSIGNMENTS
// ---------------------------------------------------------

func AssignAsset(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, assignment *AssetAssignment) (*AssetAssignment, error) {
	var created AssetAssignment
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		// 1. Create the assignment
		err := tx.QueryRow(ctx,
			`INSERT INTO asset_assignments (tenant_id, asset_id, employee_id, assigned_date, condition_out, notes)
			 VALUES ($1, $2, $3, COALESCE($4, CURRENT_DATE), $5, $6)
			 RETURNING id, tenant_id, asset_id, employee_id, assigned_date, returned_date, condition_out, condition_in, notes, created_at, updated_at`,
			tenantID, assignment.AssetID, assignment.EmployeeID, assignment.AssignedDate, assignment.ConditionOut, assignment.Notes,
		).Scan(&created.ID, &created.TenantID, &created.AssetID, &created.EmployeeID, &created.AssignedDate, &created.ReturnedDate, &created.ConditionOut, &created.ConditionIn, &created.Notes, &created.CreatedAt, &created.UpdatedAt)
		if err != nil {
			return err
		}

		// 2. Update asset status to 'assigned'
		_, err = tx.Exec(ctx, `UPDATE assets SET status = 'assigned', updated_at = now() WHERE id = $1`, assignment.AssetID)
		return err
	})
	if err != nil {
		return nil, err
	}
	return &created, nil
}

func ReturnAsset(ctx context.Context, pool *pgxpool.Pool, tenantID string, assignmentID string, conditionIn string) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var assetID uuid.UUID
		err := tx.QueryRow(ctx,
			`UPDATE asset_assignments
			 SET returned_date = CURRENT_DATE, condition_in = $1, updated_at = now()
			 WHERE id = $2
			 RETURNING asset_id`,
			conditionIn, assignmentID,
		).Scan(&assetID)
		if err != nil {
			return err
		}

		// Update asset status to 'available' and set new condition
		_, err = tx.Exec(ctx, `UPDATE assets SET status = 'available', condition = $1, updated_at = now() WHERE id = $2`, conditionIn, assetID)
		return err
	})
}

func ListAssetAssignments(ctx context.Context, pool *pgxpool.Pool, tenantID string, employeeID *string) ([]AssetAssignment, error) {
	var list []AssetAssignment
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		query := `
			SELECT aa.id, aa.tenant_id, aa.asset_id, aa.employee_id, aa.assigned_date, aa.returned_date, aa.condition_out, aa.condition_in, aa.notes, aa.created_at, aa.updated_at,
			       a.name as asset_name, e.name as employee_name
			FROM asset_assignments aa
			JOIN assets a ON aa.asset_id = a.id
			JOIN employees e ON aa.employee_id = e.id
			WHERE 1=1
		`
		var args []interface{}
		var argCount int = 1

		if employeeID != nil && *employeeID != "" {
			query += ` AND aa.employee_id = $` + javaToPgPlaceholder(argCount)
			args = append(args, *employeeID)
			argCount++
		}

		query += ` ORDER BY aa.assigned_date DESC`

		rows, err := tx.Query(ctx, query, args...)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var a AssetAssignment
			if err := rows.Scan(&a.ID, &a.TenantID, &a.AssetID, &a.EmployeeID, &a.AssignedDate, &a.ReturnedDate, &a.ConditionOut, &a.ConditionIn, &a.Notes, &a.CreatedAt, &a.UpdatedAt, &a.AssetName, &a.EmployeeName); err != nil {
				return err
			}
			list = append(list, a)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

// ---------------------------------------------------------
// ASSET REQUESTS
// ---------------------------------------------------------

func CreateAssetRequest(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, req *AssetRequest) (*AssetRequest, error) {
	var created AssetRequest
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO asset_requests (tenant_id, employee_id, requested_type, justification, status, priority, notes)
			 VALUES ($1, $2, $3, $4, COALESCE($5, 'pending'), COALESCE($6, 'normal'), $7)
			 RETURNING id, tenant_id, employee_id, requested_type, justification, status, priority, notes, created_at, updated_at`,
			tenantID, req.EmployeeID, req.RequestedType, req.Justification, req.Status, req.Priority, req.Notes,
		).Scan(&created.ID, &created.TenantID, &created.EmployeeID, &created.RequestedType, &created.Justification, &created.Status, &created.Priority, &created.Notes, &created.CreatedAt, &created.UpdatedAt)
	})
	if err != nil {
		return nil, err
	}
	return &created, nil
}

func ListAssetRequests(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]AssetRequest, error) {
	var list []AssetRequest
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT ar.id, ar.tenant_id, ar.employee_id, ar.requested_type, ar.justification, ar.status, ar.priority, ar.notes, ar.created_at, ar.updated_at,
			        e.name as employee_name
			 FROM asset_requests ar
			 JOIN employees e ON ar.employee_id = e.id
			 ORDER BY ar.created_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r AssetRequest
			if err := rows.Scan(&r.ID, &r.TenantID, &r.EmployeeID, &r.RequestedType, &r.Justification, &r.Status, &r.Priority, &r.Notes, &r.CreatedAt, &r.UpdatedAt, &r.EmployeeName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func UpdateAssetRequestStatus(ctx context.Context, pool *pgxpool.Pool, tenantID string, requestID string, status string) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE asset_requests SET status = $1, updated_at = now() WHERE id = $2`, status, requestID)
		return err
	})
}

// helper for string conversion
func javaToPgPlaceholder(i int) string {
	importStr := []string{"1", "2", "3", "4", "5", "6", "7", "8", "9"}
	if i > 0 && i <= len(importStr) {
		return importStr[i-1]
	}
	return "1" // fallback
}
