package handler

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/middleware"
	"hr-saas/internal/payroll"
	"hr-saas/internal/repository"
)

type PayrollHandler struct {
	pool *pgxpool.Pool
}

func NewPayrollHandler(pool *pgxpool.Pool) *PayrollHandler {
	return &PayrollHandler{pool: pool}
}

func (h *PayrollHandler) Run(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "invalid tenant"})
	}
	var req struct {
		Month int `json:"month"`
		Year  int `json:"year"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Month < 1 || req.Month > 12 || req.Year < 2000 || req.Year > 2100 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid month or year"})
	}
	run, err := payroll.RunPayroll(c.Context(), h.pool, tenantUUID, req.Month, req.Year)
	if err != nil {
		if err == repository.ErrPayrollRunExists {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "payroll run for this month/year already exists"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(run)
}

func (h *PayrollHandler) Lock(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	var req struct {
		ID string `json:"id"`
	}
	if err := c.BodyParser(&req); err != nil || req.ID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "id required"})
	}
	runID, err := uuid.Parse(req.ID)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	if err := repository.LockPayrollRun(c.Context(), h.pool, tenantID, runID); err != nil {
		if err == repository.ErrPayrollNotDraftOrNotFound {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "payroll run not in draft or not found"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	if err := payroll.SyncPayrollToAccounting(c.Context(), h.pool, tenantID, runID); err != nil {
		// Log but don't fail the lock; journal can be created manually
		_ = err
	}
	run, _ := repository.GetPayrollRunByID(c.Context(), h.pool, tenantID, runID)
	return c.JSON(run)
}

func (h *PayrollHandler) ListRuns(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	list, err := repository.ListPayrollRuns(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *PayrollHandler) GetRun(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	run, err := repository.GetPayrollRunByID(c.Context(), h.pool, tenantID, id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "not found"})
	}
	return c.JSON(run)
}

func (h *PayrollHandler) ListPayslips(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	runID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	list, err := repository.ListPayslipsByRunID(c.Context(), h.pool, tenantID, runID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *PayrollHandler) GetPayslipPDF(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	payslip, err := repository.GetPayslipByID(c.Context(), h.pool, tenantID, id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "not found"})
	}
	pdf, err := payroll.GeneratePayslipPDF(c.Context(), h.pool, tenantID, payslip)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	c.Set("Content-Type", "application/pdf")
	c.Set("Content-Disposition", "attachment; filename=payslip-"+id.String()+".pdf")
	return c.Send(pdf)
}
