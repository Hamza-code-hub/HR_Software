package handler

import (
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"hr-saas/internal/middleware"
)

type DepartmentHandler struct {
	pool *pgxpool.Pool
}

func NewDepartmentHandler(pool *pgxpool.Pool) *DepartmentHandler {
	return &DepartmentHandler{pool: pool}
}

// GET /api/departments
func (h *DepartmentHandler) List(c *fiber.Ctx) error {
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	rows, err := h.pool.Query(c.Context(), `
		SELECT d.id, d.name, d.manager_id, e.name AS manager_name, d.created_at
		FROM departments d
		LEFT JOIN employees e ON e.id = d.manager_id
		WHERE d.tenant_id = $1 AND d.deleted_at IS NULL
		ORDER BY d.name
	`, tenantID)
	if err != nil {
		log.Printf("DepartmentHandler.List error: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to fetch departments"})
	}
	defer rows.Close()

	type Row struct {
		ID          string  `json:"id"`
		Name        string  `json:"name"`
		ManagerID   *string `json:"manager_id"`
		ManagerName *string `json:"manager_name"`
		CreatedAt   string  `json:"created_at"`
	}
	var list []Row
	for rows.Next() {
		var r Row
		if err := rows.Scan(&r.ID, &r.Name, &r.ManagerID, &r.ManagerName, &r.CreatedAt); err != nil {
			continue
		}
		list = append(list, r)
	}
	if list == nil {
		list = []Row{}
	}
	return c.JSON(list)
}

// POST /api/departments
func (h *DepartmentHandler) Create(c *fiber.Ctx) error {
	type Req struct {
		Name      string  `json:"name"`
		ManagerID *string `json:"manager_id"`
	}
	var req Req
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Name == "" {
		return c.Status(400).JSON(fiber.Map{"error": "department name required"})
	}

	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	var id string
	err := h.pool.QueryRow(c.Context(),
		`INSERT INTO departments (tenant_id, name, manager_id) VALUES ($1, $2, $3) RETURNING id`,
		tenantID, req.Name, req.ManagerID,
	).Scan(&id)
	if err != nil {
		return c.Status(409).JSON(fiber.Map{"error": "department name already exists or db error"})
	}
	return c.Status(201).JSON(fiber.Map{"id": id, "name": req.Name})
}

// PUT /api/departments/:id
func (h *DepartmentHandler) Update(c *fiber.Ctx) error {
	id := c.Params("id")
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)

	type Req struct {
		Name      string  `json:"name"`
		ManagerID *string `json:"manager_id"`
	}
	var req Req
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}

	_, err := h.pool.Exec(c.Context(),
		`UPDATE departments SET name = $1, manager_id = $2 WHERE id = $3 AND tenant_id = $4`,
		req.Name, req.ManagerID, id, tenantID,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to update department"})
	}
	return c.JSON(fiber.Map{"message": "updated"})
}

// DELETE /api/departments/:id (soft delete)
func (h *DepartmentHandler) Delete(c *fiber.Ctx) error {
	id := c.Params("id")
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	_, err := h.pool.Exec(c.Context(),
		`UPDATE departments SET deleted_at = now() WHERE id = $1 AND tenant_id = $2`,
		id, tenantID,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to delete department"})
	}
	return c.JSON(fiber.Map{"message": "deleted"})
}
