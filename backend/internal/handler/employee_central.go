package handler

import (
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"
)

type EmployeeCentralHandler struct {
	pool *pgxpool.Pool
}

func NewEmployeeCentralHandler(pool *pgxpool.Pool) *EmployeeCentralHandler {
	return &EmployeeCentralHandler{pool: pool}
}

// ---------------------------------------------------------
// DOCUMENTS
// ---------------------------------------------------------

func (h *EmployeeCentralHandler) ListDocuments(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListEmployeeDocuments(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

// ---------------------------------------------------------
// PROBATION
// ---------------------------------------------------------

func (h *EmployeeCentralHandler) ListProbation(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListProbationTracking(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

// ---------------------------------------------------------
// PROMOTIONS
// ---------------------------------------------------------

func (h *EmployeeCentralHandler) ListPromotions(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListEmployeePromotions(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}
