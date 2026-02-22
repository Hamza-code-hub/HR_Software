package handler

import (
	"log"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"hr-saas/internal/auth"
	"hr-saas/internal/middleware"
)

type UserHandler struct {
	pool   *pgxpool.Pool
	secret string
}

func NewUserHandler(pool *pgxpool.Pool, secret string) *UserHandler {
	return &UserHandler{pool: pool, secret: secret}
}

// GET /api/users - List all users in the current tenant
func (h *UserHandler) List(c *fiber.Ctx) error {
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	ctx := c.Context()

	rows, err := h.pool.Query(ctx, `
		SELECT u.id, u.email, tu.role, u.created_at
		FROM users u
		JOIN tenant_users tu ON tu.user_id = u.id
		WHERE tu.tenant_id = $1
		ORDER BY u.created_at DESC
	`, tenantID)
	if err != nil {
		log.Printf("UserHandler.List error: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to fetch users"})
	}
	defer rows.Close()

	type UserRow struct {
		ID        string    `json:"id"`
		Email     string    `json:"email"`
		Role      string    `json:"role"`
		CreatedAt time.Time `json:"created_at"`
	}
	var users []UserRow
	for rows.Next() {
		var u UserRow
		if err := rows.Scan(&u.ID, &u.Email, &u.Role, &u.CreatedAt); err != nil {
			continue
		}
		users = append(users, u)
	}
	if users == nil {
		users = []UserRow{}
	}
	return c.JSON(users)
}

// POST /api/users - Invite/create a new user in this tenant
func (h *UserHandler) Create(c *fiber.Ctx) error {
	type Req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
		Role     string `json:"role"`
	}
	var req Req
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Email == "" || req.Password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "email and password required"})
	}
	validRoles := map[string]bool{"admin": true, "hr": true, "accounting": true, "employee": true}
	if req.Role == "" {
		req.Role = "employee"
	}
	if !validRoles[req.Role] {
		return c.Status(400).JSON(fiber.Map{"error": "invalid role. Must be one of: admin, hr, accounting, employee"})
	}

	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	ctx := c.Context()

	// Check if user already exists globally
	var existingID string
	_ = h.pool.QueryRow(ctx, `SELECT id FROM users WHERE email = $1`, req.Email).Scan(&existingID)

	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to hash password"})
	}

	tx, err := h.pool.Begin(ctx)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "db error"})
	}
	defer tx.Rollback(ctx)

	var userID string
	if existingID == "" {
		// Create new global user
		err = tx.QueryRow(ctx,
			`INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id`,
			req.Email, hash,
		).Scan(&userID)
		if err != nil {
			return c.Status(409).JSON(fiber.Map{"error": "email already registered"})
		}
	} else {
		userID = existingID
		// Update password if already exists
		_, _ = tx.Exec(ctx, `UPDATE users SET password_hash = $1 WHERE id = $2`, hash, userID)
	}

	// Add to tenant
	_, err = tx.Exec(ctx,
		`INSERT INTO tenant_users (tenant_id, user_id, role) VALUES ($1, $2, $3)
		 ON CONFLICT (tenant_id, user_id) DO UPDATE SET role = EXCLUDED.role`,
		tenantID, userID, req.Role,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to add user to tenant"})
	}

	if err := tx.Commit(ctx); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "db error"})
	}

	return c.Status(201).JSON(fiber.Map{
		"id":    userID,
		"email": req.Email,
		"role":  req.Role,
	})
}

// PUT /api/users/:id/role - Update a user's role
func (h *UserHandler) UpdateRole(c *fiber.Ctx) error {
	userID := c.Params("id")
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)

	type Req struct {
		Role string `json:"role"`
	}
	var req Req
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}
	validRoles := map[string]bool{"admin": true, "hr": true, "accounting": true, "employee": true}
	if !validRoles[req.Role] {
		return c.Status(400).JSON(fiber.Map{"error": "invalid role"})
	}

	_, err := h.pool.Exec(c.Context(),
		`UPDATE tenant_users SET role = $1 WHERE tenant_id = $2 AND user_id = $3`,
		req.Role, tenantID, userID,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to update role"})
	}
	return c.JSON(fiber.Map{"message": "role updated"})
}

// DELETE /api/users/:id - Remove user from tenant
func (h *UserHandler) Remove(c *fiber.Ctx) error {
	userID := c.Params("id")
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	callerID := c.Locals(middleware.ContextKeyUserID).(string)

	if userID == callerID {
		return c.Status(400).JSON(fiber.Map{"error": "cannot remove yourself"})
	}

	_, err := h.pool.Exec(c.Context(),
		`DELETE FROM tenant_users WHERE tenant_id = $1 AND user_id = $2`,
		tenantID, userID,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to remove user"})
	}
	return c.JSON(fiber.Map{"message": "user removed from tenant"})
}
