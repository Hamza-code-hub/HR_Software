package handler

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"
)

type EmployeeHandler struct {
	pool *pgxpool.Pool
}

func NewEmployeeHandler(pool *pgxpool.Pool) *EmployeeHandler {
	return &EmployeeHandler{pool: pool}
}

func (h *EmployeeHandler) List(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	list, err := repository.ListEmployees(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *EmployeeHandler) Get(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	emp, err := repository.GetEmployeeByID(c.Context(), h.pool, tenantID, id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "employee not found"})
	}
	return c.JSON(emp)
}

func (h *EmployeeHandler) Create(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "invalid tenant"})
	}
	var req repository.Employee
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "name required"})
	}
	if req.Status == "" {
		req.Status = "active"
	}
	created, err := repository.CreateEmployee(c.Context(), h.pool, tenantUUID, &req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}

func (h *EmployeeHandler) Update(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	var req repository.Employee
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}
	if err := repository.UpdateEmployee(c.Context(), h.pool, tenantID, id, &req); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	emp, _ := repository.GetEmployeeByID(c.Context(), h.pool, tenantID, id)
	return c.JSON(emp)
}

func (h *EmployeeHandler) Delete(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	if err := repository.SoftDeleteEmployee(c.Context(), h.pool, tenantID, id); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.SendStatus(fiber.StatusNoContent)
}
