package auth

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type TokenType string

const (
	Access  TokenType = "access"
	Refresh TokenType = "refresh"
)

type Claims struct {
	jwt.RegisteredClaims
	UserID   string   `json:"user_id"`
	TenantID string   `json:"tenant_id"`
	Email    string   `json:"email"`
	Role     string   `json:"role"`
	Type     TokenType `json:"type"`
}

func (c *Claims) Valid() error {
	if c.Type != Access && c.Type != Refresh {
		return jwt.ErrTokenInvalidClaims
	}
	if c.ExpiresAt != nil && c.ExpiresAt.Time.Before(time.Now()) {
		return jwt.ErrTokenExpired
	}
	return nil
}

type TokenPair struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	TokenType    string    `json:"token_type"`
}

func NewAccessClaims(userID, tenantID, email, role string, expMin int) *Claims {
	now := time.Now()
	return &Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Duration(expMin) * time.Minute)),
			ID:        uuid.New().String(),
		},
		UserID:   userID,
		TenantID: tenantID,
		Email:    email,
		Role:     role,
		Type:     Access,
	}
}

func NewRefreshClaims(userID string, expH int) *Claims {
	now := time.Now()
	return &Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Duration(expH) * time.Hour)),
			ID:        uuid.New().String(),
		},
		UserID: userID,
		Type:   Refresh,
	}
}
