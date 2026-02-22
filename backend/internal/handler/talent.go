package handler

import (
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type TalentHandler struct {
	pool *pgxpool.Pool
}

func NewTalentHandler(pool *pgxpool.Pool) *TalentHandler {
	return &TalentHandler{pool: pool}
}

func (h *TalentHandler) ListTrainings(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	list, err := repository.ListTrainings(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *TalentHandler) CreateTraining(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	var req repository.Training
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}

	created, err := repository.CreateTraining(c.Context(), h.pool, tenantID, &req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}

func (h *TalentHandler) ListTrainingAssignments(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	list, err := repository.ListTrainingAssignments(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *TalentHandler) ListPerformanceReviews(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	list, err := repository.ListPerformanceReviews(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}
