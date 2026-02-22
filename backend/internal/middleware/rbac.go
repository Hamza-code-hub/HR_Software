package middleware

import (
	"github.com/gofiber/fiber/v2"
)

// RequireRole returns a middleware that enforces the caller has one of the
// allowed roles as stored in the JWT / Locals by TenantFromJWT.
// Usage: api.Post("/users", middleware.RequireRole("admin"), handler.Create)
func RequireRole(allowedRoles ...string) fiber.Handler {
	allowed := make(map[string]bool, len(allowedRoles))
	for _, r := range allowedRoles {
		allowed[r] = true
	}

	return func(c *fiber.Ctx) error {
		role, _ := c.Locals(ContextKeyRole).(string)
		if role == "" {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "no role assigned",
			})
		}
		if !allowed[role] {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "insufficient permissions",
			})
		}
		return c.Next()
	}
}
