package handler

import (
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type AnnouncementHandler struct {
	pool *pgxpool.Pool
}

func NewAnnouncementHandler(pool *pgxpool.Pool) *AnnouncementHandler {
	return &AnnouncementHandler{pool: pool}
}

func (h *AnnouncementHandler) List(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListAnnouncements(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *AnnouncementHandler) Create(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	userIDStr, _ := c.Locals(middleware.ContextKeyUserID).(string)
	userID, _ := uuid.Parse(userIDStr)

	var ann repository.Announcement
	if err := c.BodyParser(&ann); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	created, err := repository.CreateAnnouncement(c.Context(), h.pool, tenantID, userID, &ann)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}
