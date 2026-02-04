package handler

import (
	"encoding/csv"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"
)

type ReportsHandler struct {
	pool *pgxpool.Pool
}

func NewReportsHandler(pool *pgxpool.Pool) *ReportsHandler {
	return &ReportsHandler{pool: pool}
}

func (h *ReportsHandler) EmployeesCSV(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	list, err := repository.ListEmployees(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	var buf strings.Builder
	w := csv.NewWriter(&buf)
	_ = w.Write([]string{"id", "employee_code", "name", "email", "designation", "status", "basic_salary", "joining_date", "created_at"})
	for _, e := range list {
		joinDate := ""
		if e.JoiningDate != nil {
			joinDate = e.JoiningDate.Format("2006-01-02")
		}
		code := ""
		if e.EmployeeCode != nil {
			code = *e.EmployeeCode
		}
		email := ""
		if e.Email != nil {
			email = *e.Email
		}
		desig := ""
		if e.Designation != nil {
			desig = *e.Designation
		}
		_ = w.Write([]string{
			e.ID.String(),
			code,
			e.Name,
			email,
			desig,
			e.Status,
			strconv.FormatFloat(e.BasicSalary, 'f', 2, 64),
			joinDate,
			e.CreatedAt.Format(time.RFC3339),
		})
	}
	w.Flush()
	c.Set("Content-Type", "text/csv")
	c.Set("Content-Disposition", "attachment; filename=employees.csv")
	return c.SendString(buf.String())
}

func (h *ReportsHandler) AttendanceCSV(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	monthStr := c.Query("month")
	yearStr := c.Query("year")
	if monthStr == "" || yearStr == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "month and year required"})
	}
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)
	if month < 1 || month > 12 || year < 2000 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid month or year"})
	}
	list, err := repository.ListAttendance(c.Context(), h.pool, tenantID, month, year)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	var buf strings.Builder
	w := csv.NewWriter(&buf)
	_ = w.Write([]string{"id", "employee_id", "date", "check_in", "check_out", "total_hours", "status"})
	for _, a := range list {
		checkIn := ""
		if a.CheckIn != nil {
			checkIn = a.CheckIn.Format(time.RFC3339)
		}
		checkOut := ""
		if a.CheckOut != nil {
			checkOut = a.CheckOut.Format(time.RFC3339)
		}
		hours := ""
		if a.TotalHours != nil {
			hours = strconv.FormatFloat(*a.TotalHours, 'f', 2, 64)
		}
		status := ""
		if a.Status != nil {
			status = *a.Status
		}
		_ = w.Write([]string{
			a.ID.String(),
			a.EmployeeID.String(),
			a.Date.Format("2006-01-02"),
			checkIn,
			checkOut,
			hours,
			status,
		})
	}
	w.Flush()
	c.Set("Content-Type", "text/csv")
	c.Set("Content-Disposition", fmt.Sprintf("attachment; filename=attendance_%d_%d.csv", year, month))
	return c.SendString(buf.String())
}

func (h *ReportsHandler) PayslipsCSV(c *fiber.Ctx) error {
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
	var buf strings.Builder
	w := csv.NewWriter(&buf)
	_ = w.Write([]string{"id", "employee_id", "basic_salary", "gross_salary", "tax", "net_salary"})
	for _, p := range list {
		_ = w.Write([]string{
			p.ID.String(),
			p.EmployeeID.String(),
			strconv.FormatFloat(p.BasicSalary, 'f', 2, 64),
			strconv.FormatFloat(p.GrossSalary, 'f', 2, 64),
			strconv.FormatFloat(p.Tax, 'f', 2, 64),
			strconv.FormatFloat(p.NetSalary, 'f', 2, 64),
		})
	}
	w.Flush()
	c.Set("Content-Type", "text/csv")
	c.Set("Content-Disposition", "attachment; filename=payslips.csv")
	return c.SendString(buf.String())
}

func (h *ReportsHandler) EmailPayslip(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid id"})
	}
	var req struct {
		Email string `json:"email"`
	}
	if err := c.BodyParser(&req); err != nil || req.Email == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "email required"})
	}
	payslip, err := repository.GetPayslipByID(c.Context(), h.pool, tenantID, id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "not found"})
	}
	// MVP: generate PDF and "send" - for now just return success; integrate SMTP later
	_ = payslip
	return c.JSON(fiber.Map{"message": "Payslip email queued (configure SMTP for actual send)", "to": req.Email})
}
