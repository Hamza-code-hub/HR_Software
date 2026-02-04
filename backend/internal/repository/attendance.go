package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/db"
)

type Attendance struct {
	ID         uuid.UUID  `json:"id"`
	TenantID   uuid.UUID  `json:"tenant_id"`
	EmployeeID uuid.UUID  `json:"employee_id"`
	Date       time.Time  `json:"date"`
	CheckIn    *time.Time `json:"check_in"`
	CheckOut   *time.Time `json:"check_out"`
	TotalHours *float64   `json:"total_hours"`
	Status     *string    `json:"status"`
	CreatedAt  time.Time  `json:"created_at"`
}

func AttendanceCheckIn(ctx context.Context, pool *pgxpool.Pool, tenantID, employeeID uuid.UUID, at time.Time) (*Attendance, error) {
	var result *Attendance
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		date := at.Truncate(24 * time.Hour)
		var att Attendance
		err := tx.QueryRow(ctx,
			`INSERT INTO attendance (tenant_id, employee_id, date, check_in, status)
			 VALUES ($1, $2, $3, $4, 'present')
			 ON CONFLICT (tenant_id, employee_id, date) DO UPDATE SET check_in = EXCLUDED.check_in
			 RETURNING id, tenant_id, employee_id, date, check_in, check_out, total_hours, status, created_at`,
			tenantID, employeeID, date, at,
		).Scan(&att.ID, &att.TenantID, &att.EmployeeID, &att.Date, &att.CheckIn, &att.CheckOut, &att.TotalHours, &att.Status, &att.CreatedAt)
		if err != nil {
			return err
		}
		result = &att
		return nil
	})
	if err != nil {
		return nil, err
	}
	return result, nil
}

// attendance table has no unique on (tenant_id, employee_id, date); we need to find today's row and update check_out
func AttendanceCheckOut(ctx context.Context, pool *pgxpool.Pool, tenantID, employeeID uuid.UUID, at time.Time) (*Attendance, error) {
	var a *Attendance
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		date := at.Truncate(24 * time.Hour)
		// get today's attendance and update check_out + total_hours
		var att Attendance
		err := tx.QueryRow(ctx,
			`UPDATE attendance SET check_out = $4, total_hours = EXTRACT(EPOCH FROM ($4 - check_in))/3600.0
			 WHERE tenant_id = $1 AND employee_id = $2 AND date = $3::date AND check_out IS NULL
			 RETURNING id, tenant_id, employee_id, date, check_in, check_out, total_hours, status, created_at`,
			tenantID, employeeID, date, at,
		).Scan(&att.ID, &att.TenantID, &att.EmployeeID, &att.Date, &att.CheckIn, &att.CheckOut, &att.TotalHours, &att.Status, &att.CreatedAt)
		if err != nil {
			return err
		}
		a = &att
		return nil
	})
	if err != nil {
		return nil, err
	}
	return a, nil
}

func ListAttendance(ctx context.Context, pool *pgxpool.Pool, tenantID string, month, year int) ([]Attendance, error) {
	var list []Attendance
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT id, tenant_id, employee_id, date, check_in, check_out, total_hours, status, created_at
			 FROM attendance
			 WHERE EXTRACT(MONTH FROM date) = $1 AND EXTRACT(YEAR FROM date) = $2
			 ORDER BY date DESC, created_at DESC`,
			month, year,
		)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var a Attendance
			err := rows.Scan(&a.ID, &a.TenantID, &a.EmployeeID, &a.Date, &a.CheckIn, &a.CheckOut, &a.TotalHours, &a.Status, &a.CreatedAt)
			if err != nil {
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
