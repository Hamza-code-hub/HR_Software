package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type OfferLetter struct {
	ID            uuid.UUID  `json:"id"`
	TenantID      uuid.UUID  `json:"tenant_id"`
	CandidateID   uuid.UUID  `json:"candidate_id"`
	JobID         uuid.UUID  `json:"job_id"`
	SalaryOffered float64    `json:"salary_offered"`
	JoiningDate   *time.Time `json:"joining_date"`
	ValidUntil    *time.Time `json:"valid_until"`
	Status        string     `json:"status"`
	Notes         *string    `json:"notes"`
	CreatedAt     time.Time  `json:"created_at"`
	// Joins
	CandidateName string `json:"candidate_name,omitempty"`
	JobTitle      string `json:"job_title,omitempty"`
}

type EmployeeContract struct {
	ID           uuid.UUID  `json:"id"`
	TenantID     uuid.UUID  `json:"tenant_id"`
	EmployeeID   uuid.UUID  `json:"employee_id"`
	ContractType string     `json:"contract_type"`
	StartDate    time.Time  `json:"start_date"`
	EndDate      *time.Time `json:"end_date"`
	Status       string     `json:"status"`
	DocumentURL  *string    `json:"document_url"`
	CreatedAt    time.Time  `json:"created_at"`
	// Joins
	EmployeeName string `json:"employee_name,omitempty"`
}

func ListOfferLetters(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]OfferLetter, error) {
	var list []OfferLetter
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT o.id, o.tenant_id, o.candidate_id, o.job_id, o.salary_offered, o.joining_date, o.valid_until, o.status, o.notes, o.created_at,
			        c.name as candidate_name, j.title as job_title
			 FROM offer_letters o
			 JOIN candidates c ON o.candidate_id = c.id
			 JOIN job_postings j ON o.job_id = j.id
			 ORDER BY o.created_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var o OfferLetter
			if err := rows.Scan(&o.ID, &o.TenantID, &o.CandidateID, &o.JobID, &o.SalaryOffered, &o.JoiningDate, &o.ValidUntil, &o.Status, &o.Notes, &o.CreatedAt, &o.CandidateName, &o.JobTitle); err != nil {
				return err
			}
			list = append(list, o)
		}
		return rows.Err()
	})
	return list, err
}

func CreateOfferLetter(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, o *OfferLetter) (*OfferLetter, error) {
	var created OfferLetter
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO offer_letters (tenant_id, candidate_id, job_id, salary_offered, joining_date, valid_until, status, notes)
			 VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, 'draft'), $8)
			 RETURNING id, tenant_id, candidate_id, job_id, salary_offered, joining_date, valid_until, status, notes, created_at`,
			tenantID, o.CandidateID, o.JobID, o.SalaryOffered, o.JoiningDate, o.ValidUntil, o.Status, o.Notes,
		).Scan(&created.ID, &created.TenantID, &created.CandidateID, &created.JobID, &created.SalaryOffered, &created.JoiningDate, &created.ValidUntil, &created.Status, &created.Notes, &created.CreatedAt)
	})
	return &created, err
}

func ListEmployeeContracts(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]EmployeeContract, error) {
	var list []EmployeeContract
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT c.id, c.tenant_id, c.employee_id, c.contract_type, c.start_date, c.end_date, c.status, c.document_url, c.created_at,
			        e.name as employee_name
			 FROM employee_contracts c
			 JOIN employees e ON c.employee_id = e.id
			 ORDER BY c.start_date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var c EmployeeContract
			if err := rows.Scan(&c.ID, &c.TenantID, &c.EmployeeID, &c.ContractType, &c.StartDate, &c.EndDate, &c.Status, &c.DocumentURL, &c.CreatedAt, &c.EmployeeName); err != nil {
				return err
			}
			list = append(list, c)
		}
		return rows.Err()
	})
	return list, err
}

func CreateEmployeeContract(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, c *EmployeeContract) (*EmployeeContract, error) {
	var created EmployeeContract
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO employee_contracts (tenant_id, employee_id, contract_type, start_date, end_date, status, document_url)
			 VALUES ($1, $2, $3, $4, $5, COALESCE($6, 'active'), $7)
			 RETURNING id, tenant_id, employee_id, contract_type, start_date, end_date, status, document_url, created_at`,
			tenantID, c.EmployeeID, c.ContractType, c.StartDate, c.EndDate, c.Status, c.DocumentURL,
		).Scan(&created.ID, &created.TenantID, &created.EmployeeID, &created.ContractType, &created.StartDate, &created.EndDate, &created.Status, &created.DocumentURL, &created.CreatedAt)
	})
	return &created, err
}
