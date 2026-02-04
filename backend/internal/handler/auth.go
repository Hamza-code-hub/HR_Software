package handler

import (
	"log"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"hr-saas/config"
	"hr-saas/internal/auth"
	"hr-saas/internal/repository"
)

type AuthHandler struct {
	cfg  *config.Config
	pool *pgxpool.Pool
}

func NewAuthHandler(cfg *config.Config, pool *pgxpool.Pool) *AuthHandler {
	return &AuthHandler{cfg: cfg, pool: pool}
}

type SignupRequest struct {
	Email      string `json:"email"`
	Password   string `json:"password"`
	TenantName string `json:"tenant_name"`
	Subdomain  string `json:"subdomain"`
}

type LoginRequest struct {
	Email     string `json:"email"`
	Password  string `json:"password"`
	TenantID  string `json:"tenant_id"`
	Subdomain string `json:"subdomain"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) Signup(c *fiber.Ctx) error {
	var req SignupRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}

	if req.Email == "" || req.Password == "" || req.TenantName == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "email, password, and tenant_name required",
		})
	}

	ctx := c.Context()
	log.Println("SIGNUP REQUEST:", req.Email, req.Subdomain)

	existing, err := repository.UserByEmail(ctx, h.pool, req.Email)
	if err != nil {
		log.Println("CHECK USER ERROR:", err)
		return c.Status(500).JSON(fiber.Map{"error": "database error"})
	}
	if existing != nil {
		return c.Status(409).JSON(fiber.Map{"error": "email already registered"})
	}

	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		log.Println("HASH PASSWORD ERROR:", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to hash password"})
	}

	tx, err := h.pool.Begin(ctx)
	if err != nil {
		log.Println("BEGIN TX ERROR:", err)
		return c.Status(500).JSON(fiber.Map{"error": "database error"})
	}
	defer tx.Rollback(ctx)

	tenant, err := repository.CreateTenantTx(ctx, tx, req.TenantName, req.Subdomain)
	if err != nil {
		log.Println("CREATE TENANT ERROR:", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to create tenant"})
	}

	user, err := repository.CreateUserTx(ctx, tx, req.Email, hash)
	if err != nil {
		log.Println("CREATE USER ERROR:", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to create user"})
	}

	_, err = repository.CreateTenantUserTx(ctx, tx, tenant.ID, user.ID, "admin")
	if err != nil {
		log.Println("CREATE TENANT_USER ERROR:", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to link user to tenant"})
	}

	if err := tx.Commit(ctx); err != nil {
		log.Println("TX COMMIT ERROR:", err)
		return c.Status(500).JSON(fiber.Map{"error": "database error"})
	}

	log.Println("SIGNUP SUCCESS:", user.Email)

	return h.issueTokenPair(c, user.ID, tenant.ID, user.Email, "admin")
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Email == "" || req.Password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "email and password required"})
	}

	ctx := c.Context()

	user, err := repository.UserByEmail(ctx, h.pool, req.Email)
	if err != nil || user == nil {
		return c.Status(401).JSON(fiber.Map{"error": "invalid credentials"})
	}

	if !auth.CheckPassword(user.PasswordHash, req.Password) {
		return c.Status(401).JSON(fiber.Map{"error": "invalid credentials"})
	}

	var tenantID uuid.UUID
	if req.TenantID != "" {
		tenantID, err = uuid.Parse(req.TenantID)
		if err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "invalid tenant_id"})
		}
	} else if req.Subdomain != "" {
		tenant, err := repository.TenantBySubdomain(ctx, h.pool, req.Subdomain)
		if err != nil || tenant == nil {
			return c.Status(400).JSON(fiber.Map{"error": "tenant not found"})
		}
		tenantID = tenant.ID
	} else {
		ids, err := repository.TenantIDsForUser(ctx, h.pool, user.ID)
		if err != nil || len(ids) == 0 {
			return c.Status(400).JSON(fiber.Map{"error": "no tenant associated"})
		}
		tenantID = ids[0]
	}

	tu, err := repository.TenantUserByTenantAndUser(ctx, h.pool, tenantID, user.ID)
	if err != nil || tu == nil {
		return c.Status(403).JSON(fiber.Map{"error": "not a member of this tenant"})
	}

	return h.issueTokenPair(c, user.ID, tenantID, user.Email, tu.Role)
}

func (h *AuthHandler) Refresh(c *fiber.Ctx) error {
	var req RefreshRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.RefreshToken == "" {
		return c.Status(400).JSON(fiber.Map{"error": "refresh_token required"})
	}

	ctx := c.Context()

	userID, err := repository.ConsumeRefreshToken(ctx, h.pool, req.RefreshToken)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "invalid or expired refresh token"})
	}

	user, err := repository.UserByID(ctx, h.pool, userID)
	if err != nil || user == nil {
		return c.Status(401).JSON(fiber.Map{"error": "user not found"})
	}

	ids, err := repository.TenantIDsForUser(ctx, h.pool, user.ID)
	if err != nil || len(ids) == 0 {
		return c.Status(400).JSON(fiber.Map{"error": "no tenant associated"})
	}

	tenantID := ids[0]
	tu, _ := repository.TenantUserByTenantAndUser(ctx, h.pool, tenantID, user.ID)
	role := "member"
	if tu != nil {
		role = tu.Role
	}

	return h.issueTokenPair(c, user.ID, tenantID, user.Email, role)
}

func (h *AuthHandler) issueTokenPair(
	c *fiber.Ctx,
	userID, tenantID uuid.UUID,
	email, role string,
) error {

	accessClaims := auth.NewAccessClaims(
		userID.String(),
		tenantID.String(),
		email,
		role,
		h.cfg.JWT.AccessExpireMin,
	)

	accessToken, err := auth.SignClaims(accessClaims, h.cfg.JWT.Secret)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to sign token"})
	}

	refreshClaims := auth.NewRefreshClaims(
		userID.String(),
		h.cfg.JWT.RefreshExpireH,
	)

	refreshToken, err := auth.SignClaims(refreshClaims, h.cfg.JWT.Secret)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to sign refresh token"})
	}

	expiresAt := time.Now().Add(
		time.Duration(h.cfg.JWT.AccessExpireMin) * time.Minute,
	)

	if err := repository.SaveRefreshToken(
		c.Context(),
		h.pool,
		userID,
		refreshToken,
		time.Now().Add(time.Duration(h.cfg.JWT.RefreshExpireH)*time.Hour),
	); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to save refresh token"})
	}

	return c.JSON(fiber.Map{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"expires_at":    expiresAt,
		"token_type":    "Bearer",
	})
}
