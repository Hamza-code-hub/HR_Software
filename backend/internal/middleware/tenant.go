package middleware

import (
	"github.com/gofiber/fiber/v2"
	"hr-saas/internal/auth"
)

const (
	ContextKeyUserID   = "user_id"
	ContextKeyTenantID = "tenant_id"
	ContextKeyRole     = "role"
	HeaderTenantID     = "X-Tenant-ID"
)

func TenantFromJWT(c *fiber.Ctx) error {
	claimsVal := c.Locals(LocalsKeyClaims)
	if claimsVal == nil {
		return c.Next()
	}
	claims, ok := claimsVal.(*auth.Claims)
	if !ok || claims == nil {
		return c.Next()
	}
	c.Locals(ContextKeyUserID, claims.UserID)
	c.Locals(ContextKeyTenantID, claims.TenantID)
	c.Locals(ContextKeyRole, claims.Role)
	return c.Next()
}

func RequireTenant(c *fiber.Ctx) error {
	tenantID := c.Locals(ContextKeyTenantID)
	if tenantID == nil || tenantID == "" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "tenant context required",
		})
	}
	return c.Next()
}
