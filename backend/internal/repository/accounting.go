package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/db"
)

type Account struct {
	ID        uuid.UUID `json:"id"`
	TenantID  uuid.UUID `json:"tenant_id"`
	Name      string    `json:"name"`
	Type      string    `json:"type"` // asset, liability, expense, revenue
	Balance   float64   `json:"balance"`
	CreatedAt time.Time `json:"created_at"`
}

type JournalEntry struct {
	ID          uuid.UUID       `json:"id"`
	TenantID    uuid.UUID       `json:"tenant_id"`
	Date        time.Time       `json:"date"`
	Description string          `json:"description"`
	Lines       []JournalLine   `json:"lines,omitempty"`
	CreatedAt   time.Time       `json:"created_at"`
}

type JournalLine struct {
	ID              uuid.UUID `json:"id"`
	TenantID        uuid.UUID `json:"tenant_id"`
	JournalEntryID  uuid.UUID `json:"journal_entry_id"`
	AccountID       uuid.UUID `json:"account_id"`
	Debit           float64   `json:"debit"`
	Credit          float64   `json:"credit"`
	CreatedAt       time.Time `json:"created_at"`
}

func ListAccounts(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Account, error) {
	var list []Account
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT id, tenant_id, name, type, COALESCE(balance, 0), created_at
			 FROM accounts WHERE deleted_at IS NULL ORDER BY name`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var a Account
			var balance float64
			if err := rows.Scan(&a.ID, &a.TenantID, &a.Name, &a.Type, &balance, &a.CreatedAt); err != nil {
				return err
			}
			a.Balance = balance
			list = append(list, a)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func GetAccountByID(ctx context.Context, pool *pgxpool.Pool, tenantID string, id uuid.UUID) (*Account, error) {
	var a *Account
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var acc Account
		var balance float64
		err := tx.QueryRow(ctx,
			`SELECT id, tenant_id, name, type, COALESCE(balance, 0), created_at
			 FROM accounts WHERE id = $1 AND deleted_at IS NULL`,
			id,
		).Scan(&acc.ID, &acc.TenantID, &acc.Name, &acc.Type, &balance, &acc.CreatedAt)
		if err != nil {
			return err
		}
		acc.Balance = balance
		a = &acc
		return nil
	})
	if err != nil {
		return nil, err
	}
	return a, nil
}

func CreateAccount(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, name, accType string) (*Account, error) {
	var created *Account
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		var a Account
		var balance float64
		err := tx.QueryRow(ctx,
			`INSERT INTO accounts (tenant_id, name, type) VALUES ($1, $2, $3)
			 RETURNING id, tenant_id, name, type, COALESCE(balance, 0), created_at`,
			tenantID, name, accType,
		).Scan(&a.ID, &a.TenantID, &a.Name, &a.Type, &balance, &a.CreatedAt)
		if err != nil {
			return err
		}
		a.Balance = balance
		created = &a
		return nil
	})
	if err != nil {
		return nil, err
	}
	return created, nil
}

func CreateJournalEntry(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, date time.Time, description string, lines []JournalLine) (*JournalEntry, error) {
	var totalDebit, totalCredit float64
	for i := range lines {
		totalDebit += lines[i].Debit
		totalCredit += lines[i].Credit
	}
	if totalDebit != totalCredit {
		return nil, ErrJournalUnbalanced
	}

	var created *JournalEntry
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		var entry JournalEntry
		err := tx.QueryRow(ctx,
			`INSERT INTO journal_entries (tenant_id, date, description) VALUES ($1, $2, $3)
			 RETURNING id, tenant_id, date, description, created_at`,
			tenantID, date, description,
		).Scan(&entry.ID, &entry.TenantID, &entry.Date, &entry.Description, &entry.CreatedAt)
		if err != nil {
			return err
		}
		for _, line := range lines {
			_, err := tx.Exec(ctx,
				`INSERT INTO journal_lines (tenant_id, journal_entry_id, account_id, debit, credit)
				 VALUES ($1, $2, $3, $4, $5)`,
				tenantID, entry.ID, line.AccountID, line.Debit, line.Credit,
			)
			if err != nil {
				return err
			}
		}
		entry.Lines = lines
		created = &entry
		return nil
	})
	if err != nil {
		return nil, err
	}
	return created, nil
}

var ErrJournalUnbalanced = errors.New("journal entry must be balanced (total debit = total credit)")

func ListJournalEntries(ctx context.Context, pool *pgxpool.Pool, tenantID string, from, to *time.Time) ([]JournalEntry, error) {
	var list []JournalEntry
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		query := `SELECT id, tenant_id, date, description, created_at FROM journal_entries WHERE 1=1`
		args := []interface{}{}
		argNum := 1
		if from != nil {
			query += ` AND date >= $` + fmt.Sprintf("%d", argNum)
			args = append(args, *from)
			argNum++
		}
		if to != nil {
			query += ` AND date <= $` + fmt.Sprintf("%d", argNum)
			args = append(args, *to)
			argNum++
		}
		query += ` ORDER BY date DESC, created_at DESC`

		rows, err := tx.Query(ctx, query, args...)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var e JournalEntry
			if err := rows.Scan(&e.ID, &e.TenantID, &e.Date, &e.Description, &e.CreatedAt); err != nil {
				return err
			}
			list = append(list, e)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func FindAccountByName(ctx context.Context, pool *pgxpool.Pool, tenantID string, name string) (*Account, error) {
	var a *Account
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		var acc Account
		var balance float64
		err := tx.QueryRow(ctx,
			`SELECT id, tenant_id, name, type, COALESCE(balance, 0), created_at
			 FROM accounts WHERE deleted_at IS NULL AND name = $1`,
			name,
		).Scan(&acc.ID, &acc.TenantID, &acc.Name, &acc.Type, &balance, &acc.CreatedAt)
		if err != nil {
			return err
		}
		acc.Balance = balance
		a = &acc
		return nil
	})
	if err != nil {
		return nil, err
	}
	return a, nil
}
