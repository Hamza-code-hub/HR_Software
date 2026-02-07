package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"hr-saas/config"
	"hr-saas/internal/db"
	"hr-saas/internal/handler"
	"hr-saas/internal/middleware"
)

func main() {
	cfg := config.Load()
	ctx := context.Background()

	// Ensure database exists and run migrations (migrations dir configurable via MIGRATIONS_DIR)
	migrationsDir := os.Getenv("MIGRATIONS_DIR")
	if migrationsDir == "" {
		migrationsDir = "migrations"
	}
	if err := db.EnsureDBAndMigrate(ctx, cfg.Database.URL, migrationsDir); err != nil {
		log.Fatalf("migrations: %v", err)
	}

	pool, err := db.NewPool(ctx, cfg.Database.URL)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()

	app := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		},
	})
	app.Use(recover.New())
	app.Use(cors.New(cors.Config{
		AllowOriginsFunc: func(origin string) bool {
			return origin == "" || strings.HasPrefix(origin, "http://localhost") || strings.HasPrefix(origin, "http://127.0.0.1")
		},
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",
	}))
	app.Use(logger.New())

	authHandler := handler.NewAuthHandler(cfg, pool)
	employeeHandler := handler.NewEmployeeHandler(pool)
	attendanceHandler := handler.NewAttendanceHandler(pool)
	payrollHandler := handler.NewPayrollHandler(pool)
	accountingHandler := handler.NewAccountingHandler(pool)
	reportsHandler := handler.NewReportsHandler(pool)
	analyticsHandler := handler.NewAnalyticsHandler()

	app.Post("/auth/signup", authHandler.Signup)
	app.Post("/auth/login", authHandler.Login)
	app.Post("/auth/refresh", authHandler.Refresh)

	api := app.Group("/api")
	api.Use(middleware.RequireAuth(cfg.JWT.Secret))
	api.Use(middleware.TenantFromJWT)
	api.Use(middleware.RequireTenant)

	api.Get("/employees", employeeHandler.List)
	api.Post("/employees", employeeHandler.Create)
	api.Get("/employees/:id", employeeHandler.Get)
	api.Put("/employees/:id", employeeHandler.Update)
	api.Delete("/employees/:id", employeeHandler.Delete)

	api.Post("/attendance/checkin", attendanceHandler.CheckIn)
	api.Post("/attendance/checkout", attendanceHandler.CheckOut)
	api.Get("/attendance", attendanceHandler.List)

	api.Post("/payroll/run", payrollHandler.Run)
	api.Post("/payroll/lock", payrollHandler.Lock)
	api.Get("/payroll", payrollHandler.ListRuns)
	api.Get("/payroll/:id", payrollHandler.GetRun)
	api.Get("/payroll/:id/payslips", payrollHandler.ListPayslips)
	api.Get("/payslips/:id/pdf", payrollHandler.GetPayslipPDF)

	api.Get("/accounts", accountingHandler.ListAccounts)
	api.Post("/accounts", accountingHandler.CreateAccount)
	api.Get("/journals", accountingHandler.ListJournals)
	api.Post("/journals", accountingHandler.CreateJournal)

	// Analytics Routes
	// HR Analytics
	api.Get("/analytics/hr/dashboard-stats", analyticsHandler.GetHRDashboardStats)
	api.Get("/analytics/hr/payroll-trend", analyticsHandler.GetPayrollTrend)
	api.Get("/analytics/hr/turnover-analysis", analyticsHandler.GetTurnoverAnalysis)
	api.Get("/analytics/hr/recruitment-funnel", analyticsHandler.GetRecruitmentFunnel)
	api.Get("/analytics/hr/leave-balance", analyticsHandler.GetLeaveBalance)
	api.Get("/analytics/hr/attendance-heatmap", analyticsHandler.GetAttendanceHeatmap)
	
	// Accounting Analytics
	api.Get("/analytics/accounting/dashboard-stats", analyticsHandler.GetAccountingDashboardStats)
	api.Get("/analytics/accounting/revenue-expenses", analyticsHandler.GetRevenueExpenses)
	api.Get("/analytics/accounting/cash-flow", analyticsHandler.GetCashFlow)
	api.Get("/analytics/accounting/aging-analysis", analyticsHandler.GetAgingAnalysis)
	api.Get("/analytics/accounting/expense-breakdown", analyticsHandler.GetExpenseBreakdown)
	api.Get("/analytics/accounting/budget-vs-actual", analyticsHandler.GetBudgetVsActual)
	api.Get("/analytics/accounting/profit-loss", analyticsHandler.GetProfitLoss)

	api.Get("/reports/employees/csv", reportsHandler.EmployeesCSV)
	api.Get("/reports/attendance/csv", reportsHandler.AttendanceCSV)
	api.Get("/reports/payroll/:id/payslips/csv", reportsHandler.PayslipsCSV)
	api.Post("/payslips/:id/email", reportsHandler.EmailPayslip)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-quit
		if err := app.Shutdown(); err != nil {
			log.Printf("shutdown: %v", err)
		}
	}()

	if err := app.Listen(":" + cfg.Server.Port); err != nil {
		log.Fatalf("listen: %v", err)
	}
}
