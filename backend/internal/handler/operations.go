package handler

import (
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type OperationsHandler struct {
	pool *pgxpool.Pool
}

func NewOperationsHandler(pool *pgxpool.Pool) *OperationsHandler {
	return &OperationsHandler{pool: pool}
}

func (h *OperationsHandler) ListShifts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListShifts(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *OperationsHandler) ListTimesheets(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListTimesheets(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *OperationsHandler) ListProjects(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	list, err := repository.ListProjects(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *OperationsHandler) CreateProject(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	var req repository.Project
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}

	created, err := repository.CreateProject(c.Context(), h.pool, tenantID, &req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}

func (h *OperationsHandler) ListOvertime(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	list, err := repository.ListOvertimeRequests(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *OperationsHandler) CreateOvertime(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	var req repository.OvertimeRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}

	created, err := repository.CreateOvertimeRequest(c.Context(), h.pool, tenantID, &req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}
