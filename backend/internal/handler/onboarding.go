package handler

import (
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type OnboardingHandler struct {
	pool *pgxpool.Pool
}

func NewOnboardingHandler(pool *pgxpool.Pool) *OnboardingHandler {
	return &OnboardingHandler{pool: pool}
}

func (h *OnboardingHandler) ListOffers(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	list, err := repository.ListOfferLetters(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *OnboardingHandler) CreateOffer(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	var req repository.OfferLetter
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}

	created, err := repository.CreateOfferLetter(c.Context(), h.pool, tenantID, &req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}

func (h *OnboardingHandler) ListContracts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	list, err := repository.ListEmployeeContracts(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *OnboardingHandler) CreateContract(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	var req repository.EmployeeContract
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}

	created, err := repository.CreateEmployeeContract(c.Context(), h.pool, tenantID, &req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}
