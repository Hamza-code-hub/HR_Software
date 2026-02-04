package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/db"
)

type Employee struct {
	ID           uuid.UUID       `json:"id"`
	TenantID     uuid.UUID       `json:"tenant_id"`
	UserID       *uuid.UUID      `json:"user_id"`
	EmployeeCode *string         `json:"employee_code"`
	Name         string          `json:"name"`
	Email        *string         `json:"email"`
	CNIC         *string         `json:"cnic"`
	Phone        *string         `json:"phone"`
	Designation  *string         `json:"designation"`
	JoiningDate  *time.Time      `json:"joining_date"`
	Status       string          `json:"status"`
	BasicSalary  float64         `json:"basic_salary,omitempty"`
	Allowances   json.RawMessage `json:"allowances,omitempty"`
	Deductions   json.RawMessage `json:"deductions,omitempty"`
	CreatedAt    time.Time       `json:"created_at"`
}

func ListEmployees(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Employee, error) {
	var list []Employee
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var err error
		list, err = ListEmployeesTx(ctx, tx)
		return err
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func ListEmployeesTx(ctx context.Context, tx pgx.Tx) ([]Employee, error) {
	rows, err := tx.Query(ctx,
		`SELECT id, tenant_id, user_id, employee_code, name, email, cnic, phone, designation, joining_date, status,
		 COALESCE(basic_salary, 0), COALESCE(allowances, '{}'), COALESCE(deductions, '{}'), created_at
		 FROM employees WHERE deleted_at IS NULL ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []Employee
	for rows.Next() {
		var e Employee
		var joiningDate *time.Time
		if err := rows.Scan(&e.ID, &e.TenantID, &e.UserID, &e.EmployeeCode, &e.Name, &e.Email, &e.CNIC, &e.Phone, &e.Designation, &joiningDate, &e.Status, &e.BasicSalary, &e.Allowances, &e.Deductions, &e.CreatedAt); err != nil {
			return nil, err
		}
		e.JoiningDate = joiningDate
		list = append(list, e)
	}
	return list, rows.Err()
}

func GetEmployeeByID(ctx context.Context, pool *pgxpool.Pool, tenantID string, id uuid.UUID) (*Employee, error) {
	var e *Employee
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var emp Employee
		var joiningDate *time.Time
		err := tx.QueryRow(ctx,
			`SELECT id, tenant_id, user_id, employee_code, name, email, cnic, phone, designation, joining_date, status,
			 COALESCE(basic_salary, 0), COALESCE(allowances, '{}'), COALESCE(deductions, '{}'), created_at
			 FROM employees WHERE id = $1 AND deleted_at IS NULL`,
			id,
		).Scan(&emp.ID, &emp.TenantID, &emp.UserID, &emp.EmployeeCode, &emp.Name, &emp.Email, &emp.CNIC, &emp.Phone, &emp.Designation, &joiningDate, &emp.Status, &emp.BasicSalary, &emp.Allowances, &emp.Deductions, &emp.CreatedAt)
		if err != nil {
			return err
		}
		emp.JoiningDate = joiningDate
		e = &emp
		return nil
	})
	if err != nil {
		return nil, err
	}
	return e, nil
}

func CreateEmployee(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, emp *Employee) (*Employee, error) {
	var created *Employee
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		var e Employee
		var joiningDate *time.Time
		err := tx.QueryRow(ctx,
			`INSERT INTO employees (tenant_id, user_id, employee_code, name, email, cnic, phone, designation, joining_date, status, basic_salary, allowances, deductions)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, 'active'), COALESCE($11, 0), COALESCE($12, '{}'), COALESCE($13, '{}'))
			 RETURNING id, tenant_id, user_id, employee_code, name, email, cnic, phone, designation, joining_date, status, basic_salary, allowances, deductions, created_at`,
			tenantID, emp.UserID, emp.EmployeeCode, emp.Name, emp.Email, emp.CNIC, emp.Phone, emp.Designation, emp.JoiningDate, emp.Status, emp.BasicSalary, emp.Allowances, emp.Deductions,
		).Scan(&e.ID, &e.TenantID, &e.UserID, &e.EmployeeCode, &e.Name, &e.Email, &e.CNIC, &e.Phone, &e.Designation, &joiningDate, &e.Status, &e.BasicSalary, &e.Allowances, &e.Deductions, &e.CreatedAt)
		if err != nil {
			return err
		}
		e.JoiningDate = joiningDate
		created = &e
		return nil
	})
	if err != nil {
		return nil, err
	}
	return created, nil
}

func UpdateEmployee(ctx context.Context, pool *pgxpool.Pool, tenantID string, id uuid.UUID, emp *Employee) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx,
			`UPDATE employees SET user_id = COALESCE($2, user_id), employee_code = COALESCE($3, employee_code), name = COALESCE($4, name),
			 email = COALESCE($5, email), cnic = COALESCE($6, cnic), phone = COALESCE($7, phone), designation = COALESCE($8, designation),
			 joining_date = COALESCE($9, joining_date), status = COALESCE($10, status), basic_salary = COALESCE($11, basic_salary), allowances = COALESCE($12, allowances), deductions = COALESCE($13, deductions)
			 WHERE id = $1 AND deleted_at IS NULL`,
			id, emp.UserID, emp.EmployeeCode, emp.Name, emp.Email, emp.CNIC, emp.Phone, emp.Designation, emp.JoiningDate, emp.Status, emp.BasicSalary, emp.Allowances, emp.Deductions,
		)
		return err
	})
}

func SoftDeleteEmployee(ctx context.Context, pool *pgxpool.Pool, tenantID string, id uuid.UUID) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE employees SET deleted_at = now() WHERE id = $1 AND deleted_at IS NULL`, id)
		return err
	})
}
