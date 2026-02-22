package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type EmployeeDocument struct {
	ID           uuid.UUID  `json:"id"`
	TenantID     uuid.UUID  `json:"tenant_id"`
	EmployeeID   uuid.UUID  `json:"employee_id"`
	DocumentName string     `json:"document_name"`
	DocumentType string     `json:"document_type"`
	DocumentURL  string     `json:"document_url"`
	UploadDate   time.Time  `json:"upload_date"`
	ExpiryDate   *time.Time `json:"expiry_date"`
	Status       string     `json:"status"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
	// Join
	EmployeeName string `json:"employee_name,omitempty"`
}

type ProbationRecord struct {
	ID         uuid.UUID  `json:"id"`
	TenantID   uuid.UUID  `json:"tenant_id"`
	EmployeeID uuid.UUID  `json:"employee_id"`
	StartDate  time.Time  `json:"start_date"`
	EndDate    time.Time  `json:"end_date"`
	Status     string     `json:"status"`
	ReviewDate *time.Time `json:"review_date"`
	Notes      *string    `json:"notes"`
	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`
	// Join
	EmployeeName string `json:"employee_name,omitempty"`
}

type EmployeePromotion struct {
	ID                  uuid.UUID `json:"id"`
	TenantID            uuid.UUID `json:"tenant_id"`
	EmployeeID          uuid.UUID `json:"employee_id"`
	PreviousDesignation string    `json:"previous_designation"`
	NewDesignation      string    `json:"new_designation"`
	PreviousSalary      float64   `json:"previous_salary"`
	NewSalary           float64   `json:"new_salary"`
	Type                string    `json:"type"`
	EffectiveDate       time.Time `json:"effective_date"`
	Notes               *string   `json:"notes"`
	Status              string    `json:"status"`
	CreatedAt           time.Time `json:"created_at"`
	UpdatedAt           time.Time `json:"updated_at"`
	// Join
	EmployeeName string `json:"employee_name,omitempty"`
}

// ---------------------------------------------------------
// DOCUMENTS
// ---------------------------------------------------------

func ListEmployeeDocuments(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]EmployeeDocument, error) {
	var list []EmployeeDocument
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT d.id, d.tenant_id, d.employee_id, d.document_name, d.document_type, d.document_url, d.upload_date, d.expiry_date, d.status, d.created_at, d.updated_at,
			        e.name as employee_name
			 FROM employee_documents d
			 JOIN employees e ON d.employee_id = e.id
			 ORDER BY d.upload_date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r EmployeeDocument
			if err := rows.Scan(&r.ID, &r.TenantID, &r.EmployeeID, &r.DocumentName, &r.DocumentType, &r.DocumentURL, &r.UploadDate, &r.ExpiryDate, &r.Status, &r.CreatedAt, &r.UpdatedAt, &r.EmployeeName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

// ---------------------------------------------------------
// PROBATION
// ---------------------------------------------------------

func ListProbationTracking(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]ProbationRecord, error) {
	var list []ProbationRecord
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT p.id, p.tenant_id, p.employee_id, p.start_date, p.end_date, p.status, p.review_date, p.notes, p.created_at, p.updated_at,
			        e.name as employee_name
			 FROM probation_tracking p
			 JOIN employees e ON p.employee_id = e.id
			 ORDER BY p.end_date ASC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r ProbationRecord
			if err := rows.Scan(&r.ID, &r.TenantID, &r.EmployeeID, &r.StartDate, &r.EndDate, &r.Status, &r.ReviewDate, &r.Notes, &r.CreatedAt, &r.UpdatedAt, &r.EmployeeName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

// ---------------------------------------------------------
// PROMOTIONS
// ---------------------------------------------------------

func ListEmployeePromotions(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]EmployeePromotion, error) {
	var list []EmployeePromotion
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT p.id, p.tenant_id, p.employee_id, p.previous_designation, p.new_designation, p.previous_salary, p.new_salary, p.type, p.effective_date, p.notes, p.status, p.created_at, p.updated_at,
			        e.name as employee_name
			 FROM employee_promotions p
			 JOIN employees e ON p.employee_id = e.id
			 ORDER BY p.effective_date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r EmployeePromotion
			if err := rows.Scan(&r.ID, &r.TenantID, &r.EmployeeID, &r.PreviousDesignation, &r.NewDesignation, &r.PreviousSalary, &r.NewSalary, &r.Type, &r.EffectiveDate, &r.Notes, &r.Status, &r.CreatedAt, &r.UpdatedAt, &r.EmployeeName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}
