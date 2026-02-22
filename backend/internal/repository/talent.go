package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Training struct {
	ID            uuid.UUID `json:"id"`
	TenantID      uuid.UUID `json:"tenant_id"`
	Title         string    `json:"title"`
	Description   string    `json:"description"`
	Trainer       string    `json:"trainer"`
	DurationHours int       `json:"duration_hours"`
	Status        string    `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type TrainingAssignment struct {
	ID             uuid.UUID  `json:"id"`
	TenantID       uuid.UUID  `json:"tenant_id"`
	TrainingID     uuid.UUID  `json:"training_id"`
	EmployeeID     uuid.UUID  `json:"employee_id"`
	AssignedDate   time.Time  `json:"assigned_date"`
	CompletionDate *time.Time `json:"completion_date,omitempty"`
	Status         string     `json:"status"`
	Notes          string     `json:"notes"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	// Join
	TrainingTitle string `json:"training_title,omitempty"`
	EmployeeName  string `json:"employee_name,omitempty"`
}

type PerformanceReview struct {
	ID           uuid.UUID `json:"id"`
	TenantID     uuid.UUID `json:"tenant_id"`
	EmployeeID   uuid.UUID `json:"employee_id"`
	ReviewerID   uuid.UUID `json:"reviewer_id"`
	ReviewDate   time.Time `json:"review_date"`
	PeriodStart  time.Time `json:"period_start"`
	PeriodEnd    time.Time `json:"period_end"`
	OverallScore float64   `json:"overall_score"`
	Comments     string    `json:"comments"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	// Join
	EmployeeName string `json:"employee_name,omitempty"`
	ReviewerName string `json:"reviewer_name,omitempty"`
}

type PerformanceGoal struct {
	ID               uuid.UUID `json:"id"`
	TenantID         uuid.UUID `json:"tenant_id"`
	EmployeeID       uuid.UUID `json:"employee_id"`
	Title            string    `json:"title"`
	Description      string    `json:"description"`
	TargetDate       time.Time `json:"target_date"`
	Weightage        int       `json:"weightage"`
	Status           string    `json:"status"`
	AchievementNotes string    `json:"achievement_notes"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// ---------------------------------------------------------
// REPOSITORY FUNCTIONS
// ---------------------------------------------------------

func ListTrainings(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Training, error) {
	var list []Training
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx, `SELECT id, tenant_id, title, description, trainer, duration_hours, status, created_at, updated_at FROM trainings ORDER BY created_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r Training
			if err := rows.Scan(&r.ID, &r.TenantID, &r.Title, &r.Description, &r.Trainer, &r.DurationHours, &r.Status, &r.CreatedAt, &r.UpdatedAt); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

func CreateTraining(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, t *Training) (*Training, error) {
	var created Training
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO trainings (tenant_id, title, description, trainer, duration_hours, status)
			 VALUES ($1, $2, $3, $4, $5, $6)
			 RETURNING id, tenant_id, title, description, trainer, duration_hours, status, created_at, updated_at`,
			tenantID, t.Title, t.Description, t.Trainer, t.DurationHours, "active",
		).Scan(&created.ID, &created.TenantID, &created.Title, &created.Description, &created.Trainer, &created.DurationHours, &created.Status, &created.CreatedAt, &created.UpdatedAt)
	})
	return &created, err
}

func ListTrainingAssignments(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]TrainingAssignment, error) {
	var list []TrainingAssignment
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT a.id, a.tenant_id, a.training_id, a.employee_id, a.assigned_date, a.completion_date, a.status, a.notes, a.created_at, a.updated_at,
			        t.title as training_title, e.name as employee_name
			 FROM training_assignments a
			 JOIN trainings t ON a.training_id = t.id
			 JOIN employees e ON a.employee_id = e.id
			 ORDER BY a.assigned_date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r TrainingAssignment
			if err := rows.Scan(&r.ID, &r.TenantID, &r.TrainingID, &r.EmployeeID, &r.AssignedDate, &r.CompletionDate, &r.Status, &r.Notes, &r.CreatedAt, &r.UpdatedAt, &r.TrainingTitle, &r.EmployeeName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

func ListPerformanceReviews(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]PerformanceReview, error) {
	var list []PerformanceReview
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT r.id, r.tenant_id, r.employee_id, r.reviewer_id, r.review_date, r.period_start, r.period_end, r.overall_score, r.comments, r.status, r.created_at, r.updated_at,
			        e.name as employee_name, rv.name as reviewer_name
			 FROM performance_reviews r
			 JOIN employees e ON r.employee_id = e.id
			 JOIN employees rv ON r.reviewer_id = rv.id
			 ORDER BY r.review_date DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r PerformanceReview
			if err := rows.Scan(&r.ID, &r.TenantID, &r.EmployeeID, &r.ReviewerID, &r.ReviewDate, &r.PeriodStart, &r.PeriodEnd, &r.OverallScore, &r.Comments, &r.Status, &r.CreatedAt, &r.UpdatedAt, &r.EmployeeName, &r.ReviewerName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}
