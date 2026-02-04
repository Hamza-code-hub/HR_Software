package repository

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/db"
)

type PayrollRun struct {
	ID        uuid.UUID `json:"id"`
	TenantID  uuid.UUID `json:"tenant_id"`
	Month     int       `json:"month"`
	Year      int       `json:"year"`
	Status    string    `json:"status"` // draft, locked, paid
	CreatedAt time.Time `json:"created_at"`
}

type Payslip struct {
	ID            uuid.UUID       `json:"id"`
	TenantID      uuid.UUID       `json:"tenant_id"`
	PayrollRunID  uuid.UUID       `json:"payroll_run_id"`
	EmployeeID    uuid.UUID       `json:"employee_id"`
	BasicSalary   float64        `json:"basic_salary"`
	Allowances    json.RawMessage `json:"allowances"`
	Deductions    json.RawMessage `json:"deductions"`
	GrossSalary   float64        `json:"gross_salary"`
	NetSalary     float64        `json:"net_salary"`
	Tax           float64        `json:"tax"`
	CreatedAt     time.Time      `json:"created_at"`
}

func CreatePayrollRun(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, month, year int) (*PayrollRun, error) {
	var run *PayrollRun
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		var err error
		run, err = CreatePayrollRunTx(ctx, tx, tenantID, month, year)
		return err
	})
	if err != nil {
		return nil, err
	}
	return run, nil
}

func CreatePayrollRunTx(ctx context.Context, tx pgx.Tx, tenantID uuid.UUID, month, year int) (*PayrollRun, error) {
	var r PayrollRun
	err := tx.QueryRow(ctx,
		`INSERT INTO payroll_runs (tenant_id, month, year, status)
		 VALUES ($1, $2, $3, 'draft')
		 RETURNING id, tenant_id, month, year, status, created_at`,
		tenantID, month, year,
	).Scan(&r.ID, &r.TenantID, &r.Month, &r.Year, &r.Status, &r.CreatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			return nil, ErrPayrollRunExists
		}
		return nil, err
	}
	return &r, nil
}

func GetPayrollRunByID(ctx context.Context, pool *pgxpool.Pool, tenantID string, id uuid.UUID) (*PayrollRun, error) {
	var run *PayrollRun
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var r PayrollRun
		err := tx.QueryRow(ctx,
			`SELECT id, tenant_id, month, year, status, created_at FROM payroll_runs WHERE id = $1`,
			id,
		).Scan(&r.ID, &r.TenantID, &r.Month, &r.Year, &r.Status, &r.CreatedAt)
		if err != nil {
			return err
		}
		run = &r
		return nil
	})
	if err != nil {
		return nil, err
	}
	return run, nil
}

func GetPayrollRunByMonthYear(ctx context.Context, pool *pgxpool.Pool, tenantID string, month, year int) (*PayrollRun, error) {
	var run *PayrollRun
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var r PayrollRun
		err := tx.QueryRow(ctx,
			`SELECT id, tenant_id, month, year, status, created_at FROM payroll_runs WHERE month = $1 AND year = $2`,
			month, year,
		).Scan(&r.ID, &r.TenantID, &r.Month, &r.Year, &r.Status, &r.CreatedAt)
		if err != nil {
			return err
		}
		run = &r
		return nil
	})
	if err != nil {
		return nil, err
	}
	return run, nil
}

func LockPayrollRun(ctx context.Context, pool *pgxpool.Pool, tenantID string, id uuid.UUID) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		res, err := tx.Exec(ctx,
			`UPDATE payroll_runs SET status = 'locked' WHERE id = $1 AND status = 'draft'`,
			id,
		)
		if err != nil {
			return err
		}
		if res.RowsAffected() == 0 {
			return ErrPayrollNotDraftOrNotFound
		}
		return nil
	})
}

func ListPayrollRuns(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]PayrollRun, error) {
	var list []PayrollRun
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT id, tenant_id, month, year, status, created_at FROM payroll_runs ORDER BY year DESC, month DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r PayrollRun
			if err := rows.Scan(&r.ID, &r.TenantID, &r.Month, &r.Year, &r.Status, &r.CreatedAt); err != nil {
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

var ErrPayrollNotDraftOrNotFound = errors.New("payroll run not in draft or not found")
var ErrPayrollRunExists = errors.New("payroll run for this month/year already exists")

func InsertPayslip(ctx context.Context, tx pgx.Tx, tenantID, payrollRunID, employeeID uuid.UUID, basicSalary float64, allowances, deductions json.RawMessage, grossSalary, netSalary, tax float64) error {
	_, err := tx.Exec(ctx,
		`INSERT INTO payslips (tenant_id, payroll_run_id, employee_id, basic_salary, allowances, deductions, gross_salary, net_salary, tax)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		tenantID, payrollRunID, employeeID, basicSalary, allowances, deductions, grossSalary, netSalary, tax,
	)
	return err
}

func ListPayslipsByRunID(ctx context.Context, pool *pgxpool.Pool, tenantID string, runID uuid.UUID) ([]Payslip, error) {
	var list []Payslip
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT id, tenant_id, payroll_run_id, employee_id, basic_salary, allowances, deductions, gross_salary, net_salary, tax, created_at
			 FROM payslips WHERE payroll_run_id = $1 ORDER BY created_at`,
			runID,
		)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var p Payslip
			if err := rows.Scan(&p.ID, &p.TenantID, &p.PayrollRunID, &p.EmployeeID, &p.BasicSalary, &p.Allowances, &p.Deductions, &p.GrossSalary, &p.NetSalary, &p.Tax, &p.CreatedAt); err != nil {
				return err
			}
			list = append(list, p)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func GetPayslipByID(ctx context.Context, pool *pgxpool.Pool, tenantID string, id uuid.UUID) (*Payslip, error) {
	var p *Payslip
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var slip Payslip
		err := tx.QueryRow(ctx,
			`SELECT id, tenant_id, payroll_run_id, employee_id, basic_salary, allowances, deductions, gross_salary, net_salary, tax, created_at
			 FROM payslips WHERE id = $1`,
			id,
		).Scan(&slip.ID, &slip.TenantID, &slip.PayrollRunID, &slip.EmployeeID, &slip.BasicSalary, &slip.Allowances, &slip.Deductions, &slip.GrossSalary, &slip.NetSalary, &slip.Tax, &slip.CreatedAt)
		if err != nil {
			return err
		}
		p = &slip
		return nil
	})
	if err != nil {
		return nil, err
	}
	return p, nil
}

func SumPayslipsNetByRunID(ctx context.Context, pool *pgxpool.Pool, tenantID string, runID uuid.UUID) (float64, error) {
	var sum float64
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`SELECT COALESCE(SUM(net_salary), 0) FROM payslips WHERE payroll_run_id = $1`,
			runID,
		).Scan(&sum)
	})
	if err != nil {
		return 0, err
	}
	return sum, nil
}
