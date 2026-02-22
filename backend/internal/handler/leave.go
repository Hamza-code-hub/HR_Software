package handler

import (
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5/pgxpool"

	"hr-saas/internal/middleware"
)

type LeaveHandler struct {
	pool *pgxpool.Pool
}

func NewLeaveHandler(pool *pgxpool.Pool) *LeaveHandler {
	return &LeaveHandler{pool: pool}
}

// GET /api/leave-types - List leave types for this tenant
func (h *LeaveHandler) ListTypes(c *fiber.Ctx) error {
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	rows, err := h.pool.Query(c.Context(), `
		SELECT id, name, days_per_year, is_paid, created_at
		FROM leave_types
		WHERE tenant_id = $1
		ORDER BY name
	`, tenantID)
	if err != nil {
		log.Printf("LeaveHandler.ListTypes error: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to fetch leave types"})
	}
	defer rows.Close()

	type Row struct {
		ID          string `json:"id"`
		Name        string `json:"name"`
		DaysPerYear int    `json:"days_per_year"`
		IsPaid      bool   `json:"is_paid"`
		CreatedAt   string `json:"created_at"`
	}
	var list []Row
	for rows.Next() {
		var r Row
		if err := rows.Scan(&r.ID, &r.Name, &r.DaysPerYear, &r.IsPaid, &r.CreatedAt); err != nil {
			continue
		}
		list = append(list, r)
	}
	if list == nil {
		list = []Row{}
	}
	return c.JSON(list)
}

// POST /api/leave-types - Create a leave type (admin/hr only)
func (h *LeaveHandler) CreateType(c *fiber.Ctx) error {
	type Req struct {
		Name        string `json:"name"`
		DaysPerYear int    `json:"days_per_year"`
		IsPaid      *bool  `json:"is_paid"`
	}
	var req Req
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Name == "" || req.DaysPerYear <= 0 {
		return c.Status(400).JSON(fiber.Map{"error": "name and days_per_year required"})
	}
	isPaid := true
	if req.IsPaid != nil {
		isPaid = *req.IsPaid
	}

	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	var id string
	err := h.pool.QueryRow(c.Context(),
		`INSERT INTO leave_types (tenant_id, name, days_per_year, is_paid) VALUES ($1, $2, $3, $4) RETURNING id`,
		tenantID, req.Name, req.DaysPerYear, isPaid,
	).Scan(&id)
	if err != nil {
		return c.Status(409).JSON(fiber.Map{"error": "leave type already exists"})
	}
	return c.Status(201).JSON(fiber.Map{"id": id, "name": req.Name})
}

// GET /api/leave-requests - List requests (all for admin/hr, own for employees)
func (h *LeaveHandler) ListRequests(c *fiber.Ctx) error {
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	role := c.Locals(middleware.ContextKeyRole).(string)
	userID := c.Locals(middleware.ContextKeyUserID).(string)

	var rows interface{ Close() }
	var err error

	if role == "admin" || role == "hr" {
		// Show all requests
		rows, err = h.pool.Query(c.Context(), `
			SELECT lr.id, lr.employee_id, e.name AS employee_name, lt.name AS leave_type,
			       lr.start_date, lr.end_date, lr.days_count, lr.reason, lr.status,
			       lr.rejection_reason, lr.created_at
			FROM leave_requests lr
			JOIN employees e ON e.id = lr.employee_id
			JOIN leave_types lt ON lt.id = lr.leave_type_id
			WHERE lr.tenant_id = $1
			ORDER BY lr.created_at DESC
		`, tenantID)
	} else {
		// Show only own requests
		rows, err = h.pool.Query(c.Context(), `
			SELECT lr.id, lr.employee_id, e.name AS employee_name, lt.name AS leave_type,
			       lr.start_date, lr.end_date, lr.days_count, lr.reason, lr.status,
			       lr.rejection_reason, lr.created_at
			FROM leave_requests lr
			JOIN employees e ON e.id = lr.employee_id AND e.user_id = $2
			JOIN leave_types lt ON lt.id = lr.leave_type_id
			WHERE lr.tenant_id = $1
			ORDER BY lr.created_at DESC
		`, tenantID, userID)
	}
	if err != nil {
		log.Printf("LeaveHandler.ListRequests error: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to fetch leave requests"})
	}

	type pgxRows interface {
		Next() bool
		Scan(dest ...interface{}) error
		Close()
	}

	r := rows.(pgxRows)
	defer r.Close()

	type Row struct {
		ID              string  `json:"id"`
		EmployeeID      string  `json:"employee_id"`
		EmployeeName    string  `json:"employee_name"`
		LeaveType       string  `json:"leave_type"`
		StartDate       string  `json:"start_date"`
		EndDate         string  `json:"end_date"`
		DaysCount       int     `json:"days_count"`
		Reason          *string `json:"reason"`
		Status          string  `json:"status"`
		RejectionReason *string `json:"rejection_reason"`
		CreatedAt       string  `json:"created_at"`
	}

	var list []Row
	for r.Next() {
		var row Row
		if scanErr := r.Scan(&row.ID, &row.EmployeeID, &row.EmployeeName, &row.LeaveType,
			&row.StartDate, &row.EndDate, &row.DaysCount, &row.Reason,
			&row.Status, &row.RejectionReason, &row.CreatedAt); scanErr != nil {
			continue
		}
		list = append(list, row)
	}
	if list == nil {
		list = []Row{}
	}
	return c.JSON(list)
}

// POST /api/leave-requests - Apply for leave
func (h *LeaveHandler) Create(c *fiber.Ctx) error {
	type Req struct {
		EmployeeID  string `json:"employee_id"`
		LeaveTypeID string `json:"leave_type_id"`
		StartDate   string `json:"start_date"`
		EndDate     string `json:"end_date"`
		Reason      string `json:"reason"`
	}
	var req Req
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.EmployeeID == "" || req.LeaveTypeID == "" || req.StartDate == "" || req.EndDate == "" {
		return c.Status(400).JSON(fiber.Map{"error": "employee_id, leave_type_id, start_date, end_date required"})
	}

	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)

	var id string
	err := h.pool.QueryRow(c.Context(), `
		INSERT INTO leave_requests (tenant_id, employee_id, leave_type_id, start_date, end_date, reason,
		  days_count)
		VALUES ($1, $2, $3, $4::date, $5::date, $6,
		  GREATEST(1, ($5::date - $4::date + 1)))
		RETURNING id
	`, tenantID, req.EmployeeID, req.LeaveTypeID, req.StartDate, req.EndDate, req.Reason).Scan(&id)
	if err != nil {
		log.Printf("LeaveHandler.Create error: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "failed to create leave request"})
	}
	return c.Status(201).JSON(fiber.Map{"id": id, "status": "pending"})
}

// PUT /api/leave-requests/:id/approve
func (h *LeaveHandler) Approve(c *fiber.Ctx) error {
	id := c.Params("id")
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	approverID := c.Locals(middleware.ContextKeyUserID).(string)

	_, err := h.pool.Exec(c.Context(), `
		UPDATE leave_requests
		SET status = 'approved', approved_by = $1, approved_at = now()
		WHERE id = $2 AND tenant_id = $3 AND status = 'pending'
	`, approverID, id, tenantID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to approve"})
	}
	return c.JSON(fiber.Map{"message": "approved"})
}

// PUT /api/leave-requests/:id/reject
func (h *LeaveHandler) Reject(c *fiber.Ctx) error {
	id := c.Params("id")
	tenantID := c.Locals(middleware.ContextKeyTenantID).(string)
	approverID := c.Locals(middleware.ContextKeyUserID).(string)

	type Req struct {
		Reason string `json:"reason"`
	}
	var req Req
	_ = c.BodyParser(&req)

	_, err := h.pool.Exec(c.Context(), `
		UPDATE leave_requests
		SET status = 'rejected', approved_by = $1, approved_at = now(), rejection_reason = $4
		WHERE id = $2 AND tenant_id = $3 AND status = 'pending'
	`, approverID, id, tenantID, req.Reason)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to reject"})
	}
	return c.JSON(fiber.Map{"message": "rejected"})
}
