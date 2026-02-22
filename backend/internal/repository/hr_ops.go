package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ResourceRequirement struct {
	ID            uuid.UUID `json:"id"`
	TenantID      uuid.UUID `json:"tenant_id"`
	RequestedByID uuid.UUID `json:"requested_by_id"`
	DepartmentID  uuid.UUID `json:"department_id"`
	ResourceName  string    `json:"resource_name"`
	Quantity      int       `json:"quantity"`
	Priority      string    `json:"priority"`
	Status        string    `json:"status"`
	Justification *string   `json:"justification"`
	RequestedDate time.Time `json:"requested_date"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
	// Joins
	RequestedByName string `json:"requested_by_name,omitempty"`
	DepartmentName  string `json:"department_name,omitempty"`
}

type Resignation struct {
	ID                  uuid.UUID  `json:"id"`
	TenantID            uuid.UUID  `json:"tenant_id"`
	EmployeeID          uuid.UUID  `json:"employee_id"`
	ResignationDate     time.Time  `json:"resignation_date"`
	LastWorkingDay      *time.Time `json:"last_working_day"`
	Reason              *string    `json:"reason"`
	Status              string     `json:"status"`
	ExitClearanceStatus string     `json:"exit_clearance_status"`
	Notes               *string    `json:"notes"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
	// Joins
	EmployeeName string `json:"employee_name,omitempty"`
}

type ExitClearanceItem struct {
	ID            uuid.UUID  `json:"id"`
	TenantID      uuid.UUID  `json:"tenant_id"`
	ResignationID uuid.UUID  `json:"resignation_id"`
	Department    string     `json:"department"`
	ItemName      string     `json:"item_name"`
	Status        string     `json:"status"`
	ClearedByID   *uuid.UUID `json:"cleared_by_id"`
	ClearedAt     *time.Time `json:"cleared_at"`
	Notes         *string    `json:"notes"`
}

type ExitInterview struct {
	ID                 uuid.UUID `json:"id"`
	TenantID           uuid.UUID `json:"tenant_id"`
	ResignationID      uuid.UUID `json:"resignation_id"`
	InterviewDate      time.Time `json:"interview_date"`
	InterviewerID      uuid.UUID `json:"interviewer_id"`
	ReasonForLeaving   string    `json:"reason_for_leaving"`
	FeedbackManagement string    `json:"feedback_management"`
	FeedbackCulture    string    `json:"feedback_culture"`
	RecommendCompany   bool      `json:"recommend_company"`
	AdditionalComments string    `json:"additional_comments"`
}

// ---------------------------------------------------------
// HIRING REQUIREMENTS
// ---------------------------------------------------------

func ListResourceRequirements(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]ResourceRequirement, error) {
	var list []ResourceRequirement
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT hr.id, hr.tenant_id, hr.requested_by_id, hr.department_id, hr.job_title as resource_name, hr.number_of_positions as quantity, 
			        hr.priority, hr.status, hr.justification, hr.requested_date, hr.created_at, hr.updated_at,
			        e.name as requested_by_name, d.name as department_name
			 FROM hiring_requirements hr
			 JOIN employees e ON hr.requested_by_id = e.id
			 JOIN departments d ON hr.department_id = d.id
			 ORDER BY hr.requested_date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r ResourceRequirement
			if err := rows.Scan(&r.ID, &r.TenantID, &r.RequestedByID, &r.DepartmentID, &r.ResourceName, &r.Quantity,
				&r.Priority, &r.Status, &r.Justification, &r.RequestedDate, &r.CreatedAt, &r.UpdatedAt,
				&r.RequestedByName, &r.DepartmentName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func CreateResourceRequirement(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, req *ResourceRequirement) (*ResourceRequirement, error) {
	var created ResourceRequirement
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO hiring_requirements (tenant_id, requested_by_id, department_id, job_title, number_of_positions, priority, status, justification)
			 VALUES ($1, $2, $3, $4, $5, COALESCE($6, 'normal'), COALESCE($7, 'pending'), $8)
			 RETURNING id, tenant_id, requested_by_id, department_id, job_title, number_of_positions, priority, status, justification, requested_date, created_at, updated_at`,
			tenantID, req.RequestedByID, req.DepartmentID, req.ResourceName, req.Quantity, req.Priority, req.Status, req.Justification,
		).Scan(&created.ID, &created.TenantID, &created.RequestedByID, &created.DepartmentID, &created.ResourceName, &created.Quantity,
			&created.Priority, &created.Status, &created.Justification, &created.RequestedDate, &created.CreatedAt, &created.UpdatedAt)
	})
	if err != nil {
		return nil, err
	}
	return &created, nil
}

func UpdateResourceRequirementStatus(ctx context.Context, pool *pgxpool.Pool, tenantID string, id string, status string) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE hiring_requirements SET status = $1, updated_at = now() WHERE id = $2`, status, id)
		return err
	})
}

// ---------------------------------------------------------
// RESIGNATIONS
// ---------------------------------------------------------

func ListResignations(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Resignation, error) {
	var list []Resignation
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT r.id, r.tenant_id, r.employee_id, r.resignation_date, r.last_working_day, r.reason, 
			        r.status, r.exit_clearance_status, r.notes, r.created_at, r.updated_at,
			        e.name as employee_name
			 FROM resignations r
			 JOIN employees e ON r.employee_id = e.id
			 ORDER BY r.resignation_date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var res Resignation
			if err := rows.Scan(&res.ID, &res.TenantID, &res.EmployeeID, &res.ResignationDate, &res.LastWorkingDay, &res.Reason,
				&res.Status, &res.ExitClearanceStatus, &res.Notes, &res.CreatedAt, &res.UpdatedAt, &res.EmployeeName); err != nil {
				return err
			}
			list = append(list, res)
		}
		return rows.Err()
	})
	if err != nil {
		return nil, err
	}
	return list, nil
}

func CreateResignation(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, res *Resignation) (*Resignation, error) {
	var created Resignation
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO resignations (tenant_id, employee_id, resignation_date, last_working_day, reason, status, exit_clearance_status, notes)
			 VALUES ($1, $2, COALESCE($3, CURRENT_DATE), $4, $5, COALESCE($6, 'pending'), COALESCE($7, 'pending'), $8)
			 RETURNING id, tenant_id, employee_id, resignation_date, last_working_day, reason, status, exit_clearance_status, notes, created_at, updated_at`,
			tenantID, res.EmployeeID, res.ResignationDate, res.LastWorkingDay, res.Reason, res.Status, res.ExitClearanceStatus, res.Notes,
		).Scan(&created.ID, &created.TenantID, &created.EmployeeID, &created.ResignationDate, &created.LastWorkingDay, &created.Reason,
			&created.Status, &created.ExitClearanceStatus, &created.Notes, &created.CreatedAt, &created.UpdatedAt)
	})
	if err != nil {
		return nil, err
	}
	return &created, nil
}

func UpdateResignationStatus(ctx context.Context, pool *pgxpool.Pool, tenantID string, id string, status string, clearanceStatus *string) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		query := `UPDATE resignations SET status = $1, updated_at = now()`
		args := []interface{}{status, id}
		if clearanceStatus != nil {
			query += `, exit_clearance_status = $3`
			args = append(args, *clearanceStatus)
		}
		_, err := tx.Exec(ctx, query+` WHERE id = $2`, args...)
		return err
	})
}

// ---------------------------------------------------------
// EXIT CLEARANCE
// ---------------------------------------------------------

func ListClearanceItems(ctx context.Context, pool *pgxpool.Pool, tenantID string, resignationID string) ([]ExitClearanceItem, error) {
	var list []ExitClearanceItem
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx, `SELECT id, tenant_id, resignation_id, department, item_name, status, cleared_by_id, cleared_at, notes FROM exit_clearance_checklists WHERE resignation_id = $1`, resignationID)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r ExitClearanceItem
			if err := rows.Scan(&r.ID, &r.TenantID, &r.ResignationID, &r.Department, &r.ItemName, &r.Status, &r.ClearedByID, &r.ClearedAt, &r.Notes); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

func UpdateClearanceItem(ctx context.Context, pool *pgxpool.Pool, tenantID string, id string, status string, notes string, userID string) error {
	return db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx, `UPDATE exit_clearance_checklists SET status = $1, notes = $2, cleared_by_id = $3, cleared_at = now(), updated_at = now() WHERE id = $4`, status, notes, userID, id)
		return err
	})
}

// ---------------------------------------------------------
// EXIT INTERVIEWS
// ---------------------------------------------------------

func GetExitInterview(ctx context.Context, pool *pgxpool.Pool, tenantID string, resignationID string) (*ExitInterview, error) {
	var r ExitInterview
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx, `SELECT id, tenant_id, resignation_id, interview_date, interviewer_id, reason_for_leaving, feedback_management, feedback_culture, recommend_company, additional_comments FROM exit_interviews WHERE resignation_id = $1`, resignationID).
			Scan(&r.ID, &r.TenantID, &r.ResignationID, &r.InterviewDate, &r.InterviewerID, &r.ReasonForLeaving, &r.FeedbackManagement, &r.FeedbackCulture, &r.RecommendCompany, &r.AdditionalComments)
	})
	if err != nil {
		return nil, err
	}
	return &r, nil
}

func SaveExitInterview(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, interview *ExitInterview) error {
	return db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		_, err := tx.Exec(ctx,
			`INSERT INTO exit_interviews (tenant_id, resignation_id, interviewer_id, reason_for_leaving, feedback_management, feedback_culture, recommend_company, additional_comments)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			 ON CONFLICT (resignation_id) DO UPDATE SET 
			    interviewer_id = EXCLUDED.interviewer_id, 
			    reason_for_leaving = EXCLUDED.reason_for_leaving,
			    feedback_management = EXCLUDED.feedback_management,
			    feedback_culture = EXCLUDED.feedback_culture,
			    recommend_company = EXCLUDED.recommend_company,
			    additional_comments = EXCLUDED.additional_comments,
			    updated_at = now()`,
			tenantID, interview.ResignationID, interview.InterviewerID, interview.ReasonForLeaving, interview.FeedbackManagement, interview.FeedbackCulture, interview.RecommendCompany, interview.AdditionalComments,
		)
		return err
	})
}
