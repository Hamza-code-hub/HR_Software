package repository

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

func SaveRefreshToken(ctx context.Context, pool *pgxpool.Pool, userID uuid.UUID, token string, expiresAt time.Time) error {
	hash := sha256.Sum256([]byte(token))
	_, err := pool.Exec(ctx,
		`INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)`,
		userID, hex.EncodeToString(hash[:]), expiresAt,
	)
	return err
}

func ConsumeRefreshToken(ctx context.Context, pool *pgxpool.Pool, token string) (userID uuid.UUID, err error) {
	hash := sha256.Sum256([]byte(token))
	err = pool.QueryRow(ctx,
		`DELETE FROM refresh_tokens WHERE token_hash = $1 AND expires_at > now() RETURNING user_id`,
		hex.EncodeToString(hash[:]),
	).Scan(&userID)
	return userID, err
}
