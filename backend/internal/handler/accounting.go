package handler

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"hr-saas/internal/middleware"
	"hr-saas/internal/repository"
)

type AccountingHandler struct {
	pool *pgxpool.Pool
}

func NewAccountingHandler(pool *pgxpool.Pool) *AccountingHandler {
	return &AccountingHandler{pool: pool}
}

func (h *AccountingHandler) ListAccounts(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	list, err := repository.ListAccounts(c.Context(), h.pool, tenantID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *AccountingHandler) CreateAccount(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "invalid tenant"})
	}
	var req struct {
		Name string `json:"name"`
		Type string `json:"type"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Name == "" || req.Type == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "name and type required"})
	}
	validTypes := map[string]bool{"asset": true, "liability": true, "expense": true, "revenue": true}
	if !validTypes[req.Type] {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "type must be asset, liability, expense, or revenue"})
	}
	acc, err := repository.CreateAccount(c.Context(), h.pool, tenantUUID, req.Name, req.Type)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(acc)
}

func (h *AccountingHandler) ListJournals(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	fromStr := c.Query("from")
	toStr := c.Query("to")
	var from, to *time.Time
	if fromStr != "" {
		t, err := time.Parse("2006-01-02", fromStr)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid from date (use YYYY-MM-DD)"})
		}
		from = &t
	}
	if toStr != "" {
		t, err := time.Parse("2006-01-02", toStr)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid to date (use YYYY-MM-DD)"})
		}
		to = &t
	}
	list, err := repository.ListJournalEntries(c.Context(), h.pool, tenantID, from, to)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(list)
}

func (h *AccountingHandler) CreateJournal(c *fiber.Ctx) error {
	tenantID, _ := c.Locals(middleware.ContextKeyTenantID).(string)
	if tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "tenant context required"})
	}
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "invalid tenant"})
	}
	var req struct {
		Date        string `json:"date"`
		Description string `json:"description"`
		Lines       []struct {
			AccountID string  `json:"account_id"`
			Debit     float64 `json:"debit"`
			Credit    float64 `json:"credit"`
		} `json:"lines"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid body"})
	}
	if req.Date == "" || len(req.Lines) == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "date and at least one line required"})
	}
	date, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid date (use YYYY-MM-DD)"})
	}
	lines := make([]repository.JournalLine, 0, len(req.Lines))
	for _, l := range req.Lines {
		accID, err := uuid.Parse(l.AccountID)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid account_id"})
		}
		lines = append(lines, repository.JournalLine{
			AccountID: accID,
			Debit:     l.Debit,
			Credit:    l.Credit,
		})
	}
	entry, err := repository.CreateJournalEntry(c.Context(), h.pool, tenantUUID, date, req.Description, lines)
	if err != nil {
		if err == repository.ErrJournalUnbalanced {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "journal must be balanced (total debit = total credit)"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(entry)
}
