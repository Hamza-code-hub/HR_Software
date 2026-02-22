package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Shift struct {
	ID                 uuid.UUID `json:"id"`
	TenantID           uuid.UUID `json:"tenant_id"`
	Name               string    `json:"name"`
	StartTime          string    `json:"start_time"` // HH:MM:SS
	EndTime            string    `json:"end_time"`   // HH:MM:SS
	GracePeriodMinutes int       `json:"grace_period_minutes"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

type Timesheet struct {
	ID              uuid.UUID `json:"id"`
	TenantID        uuid.UUID `json:"tenant_id"`
	EmployeeID      uuid.UUID `json:"employee_id"`
	Date            time.Time `json:"date"`
	TaskDescription string    `json:"task_description"`
	HoursWorked     float64   `json:"hours_worked"`
	Status          string    `json:"status"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
	// Join
	EmployeeName string `json:"employee_name,omitempty"`
}

type Project struct {
	ID          uuid.UUID  `json:"id"`
	TenantID    uuid.UUID  `json:"tenant_id"`
	Name        string     `json:"name"`
	ClientName  string     `json:"client_name"`
	Description string     `json:"description"`
	StartDate   time.Time  `json:"start_date"`
	EndDate     *time.Time `json:"end_date,omitempty"`
	Status      string     `json:"status"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

type OvertimeRequest struct {
	ID           uuid.UUID  `json:"id"`
	TenantID     uuid.UUID  `json:"tenant_id"`
	EmployeeID   uuid.UUID  `json:"employee_id"`
	Date         time.Time  `json:"date"`
	Hours        float64    `json:"hours"`
	Reason       string     `json:"reason"`
	Status       string     `json:"status"`
	ApprovedByID *uuid.UUID `json:"approved_by_id,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
	// Join
	EmployeeName string `json:"employee_name,omitempty"`
}

// ---------------------------------------------------------
// SHIFTS
// ---------------------------------------------------------

func ListShifts(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Shift, error) {
	var list []Shift
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx, `SELECT id, tenant_id, name, start_time::text, end_time::text, grace_period_minutes, created_at, updated_at FROM shifts`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r Shift
			if err := rows.Scan(&r.ID, &r.TenantID, &r.Name, &r.StartTime, &r.EndTime, &r.GracePeriodMinutes, &r.CreatedAt, &r.UpdatedAt); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

// ---------------------------------------------------------
// TIMESHEETS
// ---------------------------------------------------------

func ListTimesheets(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Timesheet, error) {
	var list []Timesheet
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT t.id, t.tenant_id, t.employee_id, t.date, t.task_description, t.hours_worked, t.status, t.created_at, t.updated_at,
			        e.name as employee_name
			 FROM timesheets t
			 JOIN employees e ON t.employee_id = e.id
			 ORDER BY t.date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r Timesheet
			if err := rows.Scan(&r.ID, &r.TenantID, &r.EmployeeID, &r.Date, &r.TaskDescription, &r.HoursWorked, &r.Status, &r.CreatedAt, &r.UpdatedAt, &r.EmployeeName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

// ---------------------------------------------------------
// PROJECTS
// ---------------------------------------------------------

func ListProjects(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Project, error) {
	var list []Project
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx, `SELECT id, tenant_id, name, client_name, description, start_date, end_date, status, created_at, updated_at FROM projects ORDER BY created_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r Project
			if err := rows.Scan(&r.ID, &r.TenantID, &r.Name, &r.ClientName, &r.Description, &r.StartDate, &r.EndDate, &r.Status, &r.CreatedAt, &r.UpdatedAt); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

func CreateProject(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, p *Project) (*Project, error) {
	var created Project
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO projects (tenant_id, name, client_name, description, start_date, end_date, status)
			 VALUES ($1, $2, $3, $4, $5, $6, $7)
			 RETURNING id, tenant_id, name, client_name, description, start_date, end_date, status, created_at, updated_at`,
			tenantID, p.Name, p.ClientName, p.Description, p.StartDate, p.EndDate, p.Status,
		).Scan(&created.ID, &created.TenantID, &created.Name, &created.ClientName, &created.Description, &created.StartDate, &created.EndDate, &created.Status, &created.CreatedAt, &created.UpdatedAt)
	})
	return &created, err
}

// ---------------------------------------------------------
// OVERTIME
// ---------------------------------------------------------

func ListOvertimeRequests(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]OvertimeRequest, error) {
	var list []OvertimeRequest
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT o.id, o.tenant_id, o.employee_id, o.date, o.hours, o.reason, o.status, o.approved_by_id, o.created_at, o.updated_at,
			        e.name as employee_name
			 FROM overtime_requests o
			 JOIN employees e ON o.employee_id = e.id
			 ORDER BY o.date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r OvertimeRequest
			if err := rows.Scan(&r.ID, &r.TenantID, &r.EmployeeID, &r.Date, &r.Hours, &r.Reason, &r.Status, &r.ApprovedByID, &r.CreatedAt, &r.UpdatedAt, &r.EmployeeName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

func CreateOvertimeRequest(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, o *OvertimeRequest) (*OvertimeRequest, error) {
	var created OvertimeRequest
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO overtime_requests (tenant_id, employee_id, date, hours, reason, status)
			 VALUES ($1, $2, $3, $4, $5, $6)
			 RETURNING id, tenant_id, employee_id, date, hours, reason, status, approved_by_id, created_at, updated_at`,
			tenantID, o.EmployeeID, o.Date, o.Hours, o.Reason, "pending",
		).Scan(&created.ID, &created.TenantID, &created.EmployeeID, &created.Date, &created.Hours, &created.Reason, &created.Status, &created.ApprovedByID, &created.CreatedAt, &created.UpdatedAt)
	})
	return &created, err
}
