package payroll

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/repository"
)

const (
	AccountSalaryExpense = "Salary Expense"
	AccountBank          = "Bank"
)

// SyncPayrollToAccounting creates a balanced journal entry for the locked payroll run.
// Debit: Salary Expense (total net), Credit: Bank (total net).
// Creates "Salary Expense" and "Bank" accounts if they don't exist.
func SyncPayrollToAccounting(ctx context.Context, pool *pgxpool.Pool, tenantID string, runID uuid.UUID) error {
	run, err := repository.GetPayrollRunByID(ctx, pool, tenantID, runID)
	if err != nil {
		return err
	}
	if run.Status != "locked" {
		return nil
	}
	total, err := repository.SumPayslipsNetByRunID(ctx, pool, tenantID, runID)
	if err != nil {
		return err
	}
	if total <= 0 {
		return nil
	}

	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return err
	}

	expenseAcc, err := repository.FindAccountByName(ctx, pool, tenantID, AccountSalaryExpense)
	if err != nil {
		expenseAcc, err = repository.CreateAccount(ctx, pool, tenantUUID, AccountSalaryExpense, "expense")
		if err != nil {
			return err
		}
	}
	bankAcc, err := repository.FindAccountByName(ctx, pool, tenantID, AccountBank)
	if err != nil {
		bankAcc, err = repository.CreateAccount(ctx, pool, tenantUUID, AccountBank, "asset")
		if err != nil {
			return err
		}
	}

	date := time.Date(run.Year, time.Month(run.Month), 1, 0, 0, 0, 0, time.UTC)
	description := fmt.Sprintf("Payroll %d/%d", run.Month, run.Year)
	lines := []repository.JournalLine{
		{AccountID: expenseAcc.ID, Debit: total, Credit: 0},
		{AccountID: bankAcc.ID, Debit: 0, Credit: total},
	}
	_, err = repository.CreateJournalEntry(ctx, pool, tenantUUID, date, description, lines)
	return err
}
