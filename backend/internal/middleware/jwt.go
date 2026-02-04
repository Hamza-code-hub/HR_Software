package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"hr-saas/internal/auth"
)

const LocalsKeyClaims = "claims"

func RequireAuth(secret string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		header := c.Get("Authorization")
		if header == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "missing authorization header"})
		}
		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid authorization format"})
		}
		tokenString := strings.TrimSpace(parts[1])
		if tokenString == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "missing token"})
		}
		claims, err := auth.ParseAndValidate(tokenString, secret)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid or expired token"})
		}
		if claims.Type != auth.Access {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid token type"})
		}
		c.Locals(LocalsKeyClaims, claims)
		return c.Next()
	}
}
