package repository

import (
	"context"
	"time"

	"hr-saas/internal/db"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Announcement struct {
	ID             uuid.UUID  `json:"id"`
	TenantID       uuid.UUID  `json:"tenant_id"`
	PostedByID     uuid.UUID  `json:"posted_by_id"`
	Title          string     `json:"title"`
	Content        string     `json:"content"`
	Priority       string     `json:"priority"`
	Category       string     `json:"category"`
	TargetAudience string     `json:"target_audience"`
	IsActive       bool       `json:"is_active"`
	ExpiresAt      *time.Time `json:"expires_at"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
	// Join
	PostedByName string `json:"posted_by_name,omitempty"`
}

func ListAnnouncements(ctx context.Context, pool *pgxpool.Pool, tenantID string) ([]Announcement, error) {
	var list []Announcement
	err := db.WithTenant(ctx, pool, tenantID, func(ctx context.Context, tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			`SELECT a.id, a.tenant_id, a.posted_by_id, a.title, a.content, a.priority, a.category, a.target_audience, a.is_active, a.expires_at, a.created_at, a.updated_at,
			        u.name as posted_by_name
			 FROM announcements a
			 JOIN users u ON a.posted_by_id = u.id
			 WHERE a.is_active = true AND (a.expires_at IS NULL OR a.expires_at > now())
			 ORDER BY a.priority = 'urgent' DESC, a.priority = 'high' DESC, a.created_at DESC`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var r Announcement
			if err := rows.Scan(&r.ID, &r.TenantID, &r.PostedByID, &r.Title, &r.Content, &r.Priority, &r.Category, &r.TargetAudience, &r.IsActive, &r.ExpiresAt, &r.CreatedAt, &r.UpdatedAt, &r.PostedByName); err != nil {
				return err
			}
			list = append(list, r)
		}
		return rows.Err()
	})
	return list, err
}

func CreateAnnouncement(ctx context.Context, pool *pgxpool.Pool, tenantID uuid.UUID, postedByID uuid.UUID, ann *Announcement) (*Announcement, error) {
	var created Announcement
	err := db.WithTenant(ctx, pool, tenantID.String(), func(ctx context.Context, tx pgx.Tx) error {
		return tx.QueryRow(ctx,
			`INSERT INTO announcements (tenant_id, posted_by_id, title, content, priority, category, target_audience, expires_at)
			 VALUES ($1, $2, $3, $4, COALESCE($5, 'normal'), COALESCE($6, 'general'), COALESCE($7, 'all'), $8)
			 RETURNING id, tenant_id, posted_by_id, title, content, priority, category, target_audience, is_active, expires_at, created_at, updated_at`,
			tenantID, postedByID, ann.Title, ann.Content, ann.Priority, ann.Category, ann.TargetAudience, ann.ExpiresAt,
		).Scan(&created.ID, &created.TenantID, &created.PostedByID, &created.Title, &created.Content, &created.Priority, &created.Category, &created.TargetAudience, &created.IsActive, &created.ExpiresAt, &created.CreatedAt, &created.UpdatedAt)
	})
	return &created, err
}
