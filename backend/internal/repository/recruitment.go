package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type JobPosting struct {
	ID             uuid.UUID `json:"id"`
	TenantID       uuid.UUID `json:"tenant_id"`
	Title          string    `json:"title"`
	Department     string    `json:"department"`
	Location       string    `json:"location"`
	EmploymentType string    `json:"employment_type"`
	Description    string    `json:"description"`
	Requirements   string    `json:"requirements"`
	Status         string    `json:"status"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

type Candidate struct {
	ID          uuid.UUID `json:"id"`
	TenantID    uuid.UUID `json:"tenant_id"`
	JobID       uuid.UUID `json:"job_id"`
	Name        string    `json:"name"`
	Email       string    `json:"email"`
	Phone       string    `json:"phone"`
	ResumeURL   string    `json:"resume_url"`
	Status      string    `json:"status"`
	Source      string    `json:"source"`
	AppliedDate time.Time `json:"applied_date"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	// Joins
	JobTitle string `json:"job_title,omitempty"`
}

type Interview struct {
	ID              uuid.UUID `json:"id"`
	TenantID        uuid.UUID `json:"tenant_id"`
	CandidateID     uuid.UUID `json:"candidate_id"`
	InterviewerID   uuid.UUID `json:"interviewer_id"`
	ScheduledAt     time.Time `json:"scheduled_at"`
	DurationMinutes int       `json:"duration_minutes"`
	Location        string    `json:"location"`
	MeetingLink     string    `json:"meeting_link"`
	Status          string    `json:"status"`
	Feedback        *string   `json:"feedback"`
	Rating          *int      `json:"rating"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
	// Joins
	CandidateName   string `json:"candidate_name,omitempty"`
	InterviewerName string `json:"interviewer_name,omitempty"`
}

// ---------------------------------------------------------
// JOB POSTINGS
// ---------------------------------------------------------

func ListJobPostings(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]JobPosting, error) {
	var list []JobPosting
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT id, tenant_id, title, department, location, employment_type, description, requirements, status, created_at, updated_at
			 FROM job_postings
			 ORDER BY created_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r JobPosting
			if err := rows.Scan(&r.ID, &r.TenantID, &r.Title, &r.Department, &r.Location, &r.EmploymentType, &r.Description, &r.Requirements, &r.Status, &r.CreatedAt, &r.UpdatedAt); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

func CreateJobPosting(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, jp *JobPosting) (*JobPosting, error) {
	var created JobPosting
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO job_postings (tenant_id, title, department, location, employment_type, description, requirements, status)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, COALESCE($8, 'open'))
			 RETURNING id, tenant_id, title, department, location, employment_type, description, requirements, status, created_at, updated_at`,
			tenantID, jp.Title, jp.Department, jp.Location, jp.EmploymentType, jp.Description, jp.Requirements, jp.Status,
		).Scan(&created.ID, &created.TenantID, &created.Title, &created.Department, &created.Location, &created.EmploymentType, &created.Description, &created.Requirements, &created.Status, &created.CreatedAt, &created.UpdatedAt)
	})
	return &created, err
}

// ---------------------------------------------------------
// CANDIDATES
// ---------------------------------------------------------

func ListCandidates(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Candidate, error) {
	var list []Candidate
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT c.id, c.tenant_id, c.job_id, c.name, c.email, c.phone, c.resume_url, c.status, c.source, c.applied_date, c.created_at, c.updated_at,
			        jp.title as job_title
			 FROM candidates c
			 LEFT JOIN job_postings jp ON c.job_id = jp.id
			 ORDER BY c.created_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r Candidate
			if err := rows.Scan(&r.ID, &r.TenantID, &r.JobID, &r.Name, &r.Email, &r.Phone, &r.ResumeURL, &r.Status, &r.Source, &r.AppliedDate, &r.CreatedAt, &r.UpdatedAt, &r.JobTitle); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

// ---------------------------------------------------------
// INTERVIEWS
// ---------------------------------------------------------

func ListInterviews(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Interview, error) {
	var list []Interview
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT i.id, i.tenant_id, i.candidate_id, i.interviewer_id, i.scheduled_at, i.duration_minutes, i.location, i.meeting_link, i.status, i.feedback, i.rating, i.created_at, i.updated_at,
			        c.name as candidate_name, e.name as interviewer_name
			 FROM interviews i
			 JOIN candidates c ON i.candidate_id = c.id
			 LEFT JOIN employees e ON i.interviewer_id = e.id
			 ORDER BY i.scheduled_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r Interview
			if err := rows.Scan(&r.ID, &r.TenantID, &r.CandidateID, &r.InterviewerID, &r.ScheduledAt, &r.DurationMinutes, &r.Location, &r.MeetingLink, &r.Status, &r.Feedback, &r.Rating, &r.CreatedAt, &r.UpdatedAt, &r.CandidateName, &r.InterviewerName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}
