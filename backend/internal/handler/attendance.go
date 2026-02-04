package handler

import (
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"
)

type AttendanceHandler struct {
	pool *pgxpool.Pool
}

func NewAttendanceHandler(pool *pgxpool.Pool) *AttendanceHandler {
	return &AttendanceHandler{pool: pool}
}

func (h *AttendanceHandler) CheckIn(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "invalid tenant"})
	}
	var req struct {
		EmployeeID string `json:"employee_id"`
	}
	if err := c.BodyParser(&req); err != nil || req.EmployeeID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "employee_id required"})
	}
	employeeUUID, err := uuid.Parse(req.EmployeeID)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid employee_id"})
	}
	now := time.Now()
	att, err := repository.AttendanceCheckIn(c.Context(), h.pool, tenantUUID, employeeUUID, now)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(att)
}

func (h *AttendanceHandler) CheckOut(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "invalid tenant"})
	}
	var req struct {
		EmployeeID string `json:"employee_id"`
	}
	if err := c.BodyParser(&req); err != nil || req.EmployeeID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "employee_id required"})
	}
	employeeUUID, err := uuid.Parse(req.EmployeeID)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid employee_id"})
	}
	now := time.Now()
	att, err := repository.AttendanceCheckOut(c.Context(), h.pool, tenantUUID, employeeUUID, now)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(att)
}

func (h *AttendanceHandler) List(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	monthStr := c.Query("month")
	yearStr := c.Query("year")
	if monthStr == "" || yearStr == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "month and year query params required"})
	}
	month, err := strconv.Atoi(monthStr)
	if err != nil || month < 1 || month > 12 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid month"})
	}
	year, err := strconv.Atoi(yearStr)
	if err != nil || year < 2000 || year > 2100 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid year"})
	}
	list, err := repository.ListAttendance(c.Context(), h.pool, tenantID, month, year)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}
