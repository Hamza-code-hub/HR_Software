package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type User struct {
	ID           uuid.UUID `json:"id"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
}

// ✅ FIXED: ErrNoRows is NOT an error
func UserByEmail(ctx context.Context, pool *pgxpool.Pool, email string) (*User, error) {
	var u User
	err := pool.QueryRow(ctx,
		`SELECT id, email, password_hash FROM users WHERE email = $1`,
		email,
	).Scan(&u.ID, &u.Email, &u.PasswordHash)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil // 👈 THIS IS THE FIX
		}
		return nil, err
	}

	return &u, nil
}

// ✅ FIXED: same handling for ID lookup
func UserByID(ctx context.Context, pool *pgxpool.Pool, id uuid.UUID) (*User, error) {
	var u User
	err := pool.QueryRow(ctx,
		`SELECT id, email, password_hash FROM users WHERE id = $1`,
		id,
	).Scan(&u.ID, &u.Email, &u.PasswordHash)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &u, nil
}

func CreateUser(ctx context.Context, pool *pgxpool.Pool, email, passwordHash string) (*User, error) {
	var u User
	err := pool.QueryRow(ctx,
		`INSERT INTO users (email, password_hash)
		 VALUES ($1, $2)
		 RETURNING id, email, password_hash`,
		email, passwordHash,
	).Scan(&u.ID, &u.Email, &u.PasswordHash)

	if err != nil {
		return nil, err
	}

	return &u, nil
}

type TenantUser struct {
	ID       uuid.UUID `json:"id"`
	TenantID uuid.UUID `json:"tenant_id"`
	UserID   uuid.UUID `json:"user_id"`
	Role     string    `json:"role"`
}

// ✅ FIXED: ErrNoRows handled
func TenantUserByTenantAndUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	tenantID, userID uuid.UUID,
) (*TenantUser, error) {

	var tu TenantUser
	err := pool.QueryRow(ctx,
		`SELECT id, tenant_id, user_id, role
		 FROM tenant_users
		 WHERE tenant_id = $1 AND user_id = $2`,
		tenantID, userID,
	).Scan(&tu.ID, &tu.TenantID, &tu.UserID, &tu.Role)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &tu, nil
}

func CreateTenantUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	tenantID, userID uuid.UUID,
	role string,
) (*TenantUser, error) {

	var tu TenantUser
	err := pool.QueryRow(ctx,
		`INSERT INTO tenant_users (tenant_id, user_id, role)
		 VALUES ($1, $2, $3)
		 RETURNING id, tenant_id, user_id, role`,
		tenantID, userID, role,
	).Scan(&tu.ID, &tu.TenantID, &tu.UserID, &tu.Role)

	if err != nil {
		return nil, err
	}

	return &tu, nil
}

func CreateUserTx(
	ctx context.Context,
	tx pgx.Tx,
	email, passwordHash string,
) (*User, error) {

	var u User
	err := tx.QueryRow(ctx,
		`INSERT INTO users (email, password_hash)
		 VALUES ($1, $2)
		 RETURNING id, email, password_hash`,
		email, passwordHash,
	).Scan(&u.ID, &u.Email, &u.PasswordHash)

	if err != nil {
		return nil, err
	}

	return &u, nil
}

func CreateTenantUserTx(
	ctx context.Context,
	tx pgx.Tx,
	tenantID, userID uuid.UUID,
	role string,
) (*TenantUser, error) {

	var tu TenantUser
	err := tx.QueryRow(ctx,
		`INSERT INTO tenant_users (tenant_id, user_id, role)
		 VALUES ($1, $2, $3)
		 RETURNING id, tenant_id, user_id, role`,
		tenantID, userID, role,
	).Scan(&tu.ID, &tu.TenantID, &tu.UserID, &tu.Role)

	if err != nil {
		return nil, err
	}

	return &tu, nil
}

func TenantIDsForUser(
	ctx context.Context,
	pool *pgxpool.Pool,
	userID uuid.UUID,
) ([]uuid.UUID, error) {

	rows, err := pool.Query(ctx,
		`SELECT tenant_id FROM tenant_users WHERE user_id = $1`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}

	return ids, rows.Err()
}
