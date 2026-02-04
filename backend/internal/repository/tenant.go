package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5"
)

type Tenant struct {
	ID                 uuid.UUID `json:"id"`
	CompanyName        string    `json:"company_name"`
	Subdomain          *string   `json:"subdomain"`
	SubscriptionTier   *string   `json:"subscription_tier"`
	SubscriptionStatus *string   `json:"subscription_status"`
}

func TenantByID(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) (*Tenant, error) {
	var t Tenant
	err := pool.QueryRow(ctx,
		`SELECT id, company_name, subdomain, subscription_tier, subscription_status
		 FROM tenants WHERE id = $1`,
		id,
	).Scan(&t.ID, &t.CompanyName, &t.Subdomain, &t.SubscriptionTier, &t.SubscriptionStatus)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func TenantBySubdomain(ctx context.Context, pool *pgxpool.Pool, subdomain string) (*Tenant, error) {
	var t Tenant
	err := pool.QueryRow(ctx,
		`SELECT id, company_name, subdomain, subscription_tier, subscription_status
		 FROM tenants WHERE subdomain = $1`,
		subdomain,
	).Scan(&t.ID, &t.CompanyName, &t.Subdomain, &t.SubscriptionTier, &t.SubscriptionStatus)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func CreateTenant(ctx context.Context, pool *pgxpool.Pool, companyName, subdomain string) (*Tenant, error) {
	var t Tenant
	err := pool.QueryRow(ctx,
		`INSERT INTO tenants (company_name, subdomain) VALUES ($1, NULLIF($2, ''))
		 RETURNING id, company_name, subdomain, subscription_tier, subscription_status`,
		companyName, subdomain,
	).Scan(&t.ID, &t.CompanyName, &t.Subdomain, &t.SubscriptionTier, &t.SubscriptionStatus)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func CreateTenantTx(ctx context.Context, tx pgx.Tx, companyName, subdomain string) (*Tenant, error) {
	var t Tenant
	err := tx.QueryRow(ctx,
		`INSERT INTO tenants (company_name, subdomain) VALUES ($1, NULLIF($2, ''))
		 RETURNING id, company_name, subdomain, subscription_tier, subscription_status`,
		companyName, subdomain,
	).Scan(&t.ID, &t.CompanyName, &t.Subdomain, &t.SubscriptionTier, &t.SubscriptionStatus)
	if err != nil {
		return nil, err
	}
	return &t, nil
}
