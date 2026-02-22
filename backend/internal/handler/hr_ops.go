package handler

import (
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type HROpsHandler struct {
	pool *pgxpool.Pool
}

func NewHROpsHandler(pool *pgxpool.Pool) *HROpsHandler {
	return &HROpsHandler{pool: pool}
}

// ---------------------------------------------------------
// HIRING REQUIREMENTS
// ---------------------------------------------------------

func (h *HROpsHandler) ListResourceRequirements(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListResourceRequirements(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *HROpsHandler) CreateResourceRequirement(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	var req repository.ResourceRequirement
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	created, err := repository.CreateResourceRequirement(c.Context(), h.pool, tenantID, &req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}

func (h *HROpsHandler) ApproveResourceRequirement(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	id := c.Params("id")

	err := repository.UpdateResourceRequirementStatus(c.Context(), h.pool, tenantID, id, "approved")
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.SendStatus(fiber.StatusOK)
}

func (h *HROpsHandler) RejectResourceRequirement(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	id := c.Params("id")

	err := repository.UpdateResourceRequirementStatus(c.Context(), h.pool, tenantID, id, "rejected")
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.SendStatus(fiber.StatusOK)
}

// ---------------------------------------------------------
// RESIGNATIONS
// ---------------------------------------------------------

func (h *HROpsHandler) ListResignations(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}

	list, err := repository.ListResignations(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *HROpsHandler) CreateResignation(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)

	var res repository.Resignation
	if err := c.BodyParser(&res); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	created, err := repository.CreateResignation(c.Context(), h.pool, tenantID, &res)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(created)
}

func (h *HROpsHandler) UpdateResignationStatus(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	id := c.Params("id")

	type UpdateRequest struct {
		Status              string  `json:"status"`
		ExitClearanceStatus *string `json:"exit_clearance_status"`
	}

	var req UpdateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	err := repository.UpdateResignationStatus(c.Context(), h.pool, tenantID, id, req.Status, req.ExitClearanceStatus)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.SendStatus(fiber.StatusOK)
}

// ---------------------------------------------------------
// EXIT CLEARANCE
// ---------------------------------------------------------

func (h *HROpsHandler) ListClearance(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	resignationID := c.Params("id")

	list, err := repository.ListClearanceItems(c.Context(), h.pool, tenantID, resignationID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *HROpsHandler) UpdateClearance(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	userID, _ := c.Locals(middleware.ContextKeyUserID).(string)
	id := c.Params("itemId")

	var req struct {
		Status string `json:"status"`
		Notes  string `json:"notes"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	err := repository.UpdateClearanceItem(c.Context(), h.pool, tenantID, id, req.Status, req.Notes, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.SendStatus(fiber.StatusOK)
}

// ---------------------------------------------------------
// EXIT INTERVIEW
// ---------------------------------------------------------

func (h *HROpsHandler) GetInterview(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	resignationID := c.Params("id")

	interview, err := repository.GetExitInterview(c.Context(), h.pool, tenantID, resignationID)
	if err != nil {
		return c.JSON(nil) // Return null if not found
	}
	return c.JSON(interview)
}

func (h *HROpsHandler) SaveInterview(c *fiber.Ctx) error {
	tenantIDStr, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	tenantID, _ := uuid.Parse(tenantIDStr)
	userIDStr, _ := c.Locals(middleware.ContextKeyUserID).(string)
	userID, _ := uuid.Parse(userIDStr)

	var interview repository.ExitInterview
	if err := c.BodyParser(&interview); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}
	interview.TenantID = tenantID
	interview.InterviewerID = userID

	err := repository.SaveExitInterview(c.Context(), h.pool, tenantID, &interview)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.SendStatus(fiber.StatusOK)
}
