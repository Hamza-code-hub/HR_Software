package payroll

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/db"
	"hr-saas/internal/repository"
)

// TaxVersion MVP: simple slab (versioned for future changes)
const TaxVersion = "v1_mvp"

// CalculateTaxMVP returns tax for gross salary (MVP: 0% or simple slab)
func CalculateTaxMVP(gross float64) float64 {
	if gross <= 0 {
		return 0
	}
	// MVP: 5% above 50,000/month threshold (example; configurable later)
	const threshold = 50000
	const rate = 0.05
	if gross <= threshold {
		return 0
	}
	return (gross - threshold) * rate
}

// sumAllowancesOrDeductions sums numeric values from a JSON object like {"housing": 10000, "transport": 2000}
func sumAllowancesOrDeductions(raw json.RawMessage) float64 {
	if len(raw) == 0 {
		return 0
	}
	var m map[string]interface{}
	if err := json.Unmarshal(raw, &m); err != nil {
		return 0
	}
	var sum float64
	for _, v := range m {
		switch n := v.(type) {
		case float64:
			sum += n
		case int:
			sum += float64(n)
		}
	}
	return sum
}

// RunPayroll creates a draft payroll run and snapshot payslips for the given month/year in one transaction.
// Only active employees are included.
func RunPayroll(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, month, year int) (*repository.PayrollRun, error) {
	var run *repository.PayrollRun
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		var err error
		run, err = repository.CreatePayrollRunTx(ctx, tx, tenantID, month, year)
		if err != nil {
			return err
		}
		employees, err := repository.ListEmployeesTx(ctx, tx)
		if err != nil {
			return err
		}
		for _, emp := range employees {
			if emp.Status != "active" {
				continue
			}
			allowSum := sumAllowancesOrDeductions(emp.Allowances)
			deductSum := sumAllowancesOrDeductions(emp.Deductions)
			gross := emp.BasicSalary + allowSum
			tax := CalculateTaxMVP(gross)
			net := gross - tax - deductSum
			if net < 0 {
				net = 0
			}
			allowances := emp.Allowances
			if allowances == nil {
				allowances = []byte("{}")
			}
			deductions := emp.Deductions
			if deductions == nil {
				deductions = []byte("{}")
			}
			if err := repository.InsertPayslip(ctx, tx, tenantID, run.ID, emp.ID, emp.BasicSalary, allowances, deductions, gross, net, tax); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return run, nil
}
