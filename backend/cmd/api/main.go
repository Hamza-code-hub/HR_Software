package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"hr-saas/config"
	"hr-saas/internal/db"
	"hr-saas/internal/handler"
	"hr-saas/internal/middleware"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	cfg := config.Load()
	ctx := context.Background()

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
			return origin == "" ||
				strings.HasPrefix(origin, "http://localhost") ||
				strings.HasPrefix(origin, "http://127.0.0.1")
		},
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",
	}))
	app.Use(logger.New())

	// --- Handlers ---
	authHandler := handler.NewAuthHandler(cfg, pool)
	employeeHandler := handler.NewEmployeeHandler(pool)
	attendanceHandler := handler.NewAttendanceHandler(pool)
	payrollHandler := handler.NewPayrollHandler(pool)
	accountingHandler := handler.NewAccountingHandler(pool)
	reportsHandler := handler.NewReportsHandler(pool)
	analyticsHandler := handler.NewAnalyticsHandler()
	userHandler := handler.NewUserHandler(pool, cfg.JWT.Secret)
	departmentHandler := handler.NewDepartmentHandler(pool)
	leaveHandler := handler.NewLeaveHandler(pool)
	assetHandler := handler.NewAssetHandler(pool)
	hrOpsHandler := handler.NewHROpsHandler(pool)
	recruitmentHandler := handler.NewRecruitmentHandler(pool)
	employeeCentralHandler := handler.NewEmployeeCentralHandler(pool)
	announcementHandler := handler.NewAnnouncementHandler(pool)
	operationsHandler := handler.NewOperationsHandler(pool)
	onboardingHandler := handler.NewOnboardingHandler(pool)
	talentHandler := handler.NewTalentHandler(pool)

	// --- Public Auth Routes ---
	app.Post("/auth/signup", authHandler.Signup)
	app.Post("/auth/login", authHandler.Login)
	app.Post("/auth/refresh", authHandler.Refresh)

	// --- Protected API (requires JWT + tenant context) ---
	api := app.Group("/api")
	api.Use(middleware.RequireAuth(cfg.JWT.Secret))
	api.Use(middleware.TenantFromJWT)
	api.Use(middleware.RequireTenant)

	// Current user's profile (for session init on frontend)
	api.Get("/me", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"user_id":   c.Locals(middleware.ContextKeyUserID),
			"tenant_id": c.Locals(middleware.ContextKeyTenantID),
			"role":      c.Locals(middleware.ContextKeyRole),
		})
	})

	// --- User Management (admin only) ---
	api.Get("/users", middleware.RequireRole("admin"), userHandler.List)
	api.Post("/users", middleware.RequireRole("admin"), userHandler.Create)
	api.Put("/users/:id/role", middleware.RequireRole("admin"), userHandler.UpdateRole)
	api.Delete("/users/:id", middleware.RequireRole("admin"), userHandler.Remove)

	// --- Department Management (admin, hr) ---
	api.Get("/departments", departmentHandler.List)
	api.Post("/departments", middleware.RequireRole("admin", "hr"), departmentHandler.Create)
	api.Put("/departments/:id", middleware.RequireRole("admin", "hr"), departmentHandler.Update)
	api.Delete("/departments/:id", middleware.RequireRole("admin", "hr"), departmentHandler.Delete)

	// --- Leave Management ---
	api.Get("/leave-types", leaveHandler.ListTypes)
	api.Post("/leave-types", middleware.RequireRole("admin", "hr"), leaveHandler.CreateType)
	api.Get("/leave-requests", leaveHandler.ListRequests)
	api.Post("/leave-requests", leaveHandler.Create)
	api.Put("/leave-requests/:id/approve", middleware.RequireRole("admin", "hr"), leaveHandler.Approve)
	api.Put("/leave-requests/:id/reject", middleware.RequireRole("admin", "hr"), leaveHandler.Reject)

	// --- Employees (admin, hr) ---
	api.Get("/employees/me", employeeHandler.Me)
	api.Get("/employees", employeeHandler.List)
	api.Post("/employees", middleware.RequireRole("admin", "hr"), employeeHandler.Create)
	api.Get("/employees/:id", employeeHandler.Get)
	api.Put("/employees/:id", middleware.RequireRole("admin", "hr"), employeeHandler.Update)
	api.Delete("/employees/:id", middleware.RequireRole("admin", "hr"), employeeHandler.Delete)

	// --- Assets (admin, hr, employee) ---
	api.Get("/assets", middleware.RequireRole("admin", "hr"), assetHandler.ListAssets)
	api.Post("/assets", middleware.RequireRole("admin", "hr"), assetHandler.CreateAsset)
	api.Put("/assets/:id", middleware.RequireRole("admin", "hr"), assetHandler.UpdateAsset)
	api.Delete("/assets/:id", middleware.RequireRole("admin", "hr"), assetHandler.DeleteAsset)
	api.Get("/assets/assignments", middleware.RequireRole("admin", "hr"), assetHandler.ListAssignments)
	api.Post("/assets/assignments", middleware.RequireRole("admin", "hr"), assetHandler.AssignAsset)
	api.Put("/assets/assignments/:id/return", middleware.RequireRole("admin", "hr"), assetHandler.ReturnAsset)
	api.Get("/asset-requests", middleware.RequireRole("admin", "hr"), assetHandler.ListAssetRequests)
	api.Post("/asset-requests", assetHandler.CreateAssetRequest) // Employees can create requests
	api.Put("/asset-requests/:id/status", middleware.RequireRole("admin", "hr"), assetHandler.UpdateAssetRequestStatus)

	// --- Attendance ---
	api.Post("/attendance/checkin", attendanceHandler.CheckIn)
	api.Post("/attendance/checkout", attendanceHandler.CheckOut)
	api.Get("/attendance", attendanceHandler.List)

	// --- Payroll (admin, hr) ---
	api.Post("/payroll/run", middleware.RequireRole("admin", "hr"), payrollHandler.Run)
	api.Post("/payroll/lock", middleware.RequireRole("admin", "hr"), payrollHandler.Lock)
	api.Get("/payroll", payrollHandler.ListRuns)
	api.Get("/payroll/:id", payrollHandler.GetRun)
	api.Get("/payroll/:id/payslips", payrollHandler.ListPayslips)
	api.Get("/payslips/:id/pdf", payrollHandler.GetPayslipPDF)

	// --- Resource Requirements (Equipment, etc.) ---
	api.Get("/resource-requirements", hrOpsHandler.ListResourceRequirements)
	api.Post("/resource-requirements", hrOpsHandler.CreateResourceRequirement)
	api.Put("/resource-requirements/:id/approve", middleware.RequireRole("admin", "hr"), hrOpsHandler.ApproveResourceRequirement)
	api.Put("/resource-requirements/:id/reject", middleware.RequireRole("admin", "hr"), hrOpsHandler.RejectResourceRequirement)
	api.Get("/resignations", hrOpsHandler.ListResignations)
	api.Post("/resignations", hrOpsHandler.CreateResignation)
	api.Put("/resignations/:id/status", middleware.RequireRole("admin", "hr"), hrOpsHandler.UpdateResignationStatus)
	api.Get("/resignations/:id/clearance", hrOpsHandler.ListClearance)
	api.Put("/resignations/clearance/:itemId", middleware.RequireRole("admin", "hr"), hrOpsHandler.UpdateClearance)
	api.Get("/resignations/:id/interview", hrOpsHandler.GetInterview)
	api.Post("/resignations/interview", middleware.RequireRole("admin", "hr"), hrOpsHandler.SaveInterview)

	// --- Recruitment ---
	api.Get("/recruitment/postings", recruitmentHandler.ListJobPostings)
	api.Post("/recruitment/postings", middleware.RequireRole("admin", "hr"), recruitmentHandler.CreateJobPosting)
	api.Get("/recruitment/candidates", recruitmentHandler.ListCandidates)
	api.Get("/recruitment/interviews", recruitmentHandler.ListInterviews)

	// --- Employee Central ---
	api.Get("/employee-central/documents", employeeCentralHandler.ListDocuments)
	api.Get("/employee-central/probation", employeeCentralHandler.ListProbation)
	api.Get("/employee-central/promotions", employeeCentralHandler.ListPromotions)

	// --- Talent Management ---
	api.Get("/talent/trainings", talentHandler.ListTrainings)
	api.Post("/talent/trainings", middleware.RequireRole("admin", "hr"), talentHandler.CreateTraining)
	api.Get("/talent/training-assignments", talentHandler.ListTrainingAssignments)
	api.Get("/talent/performance-reviews", talentHandler.ListPerformanceReviews)

	// --- Announcements ---
	api.Get("/announcements", announcementHandler.List)
	api.Post("/announcements", middleware.RequireRole("admin", "hr"), announcementHandler.Create)

	// --- Operations ---
	api.Get("/operations/shifts", operationsHandler.ListShifts)
	api.Get("/operations/timesheets", operationsHandler.ListTimesheets)
	api.Get("/operations/projects", operationsHandler.ListProjects)
	api.Post("/operations/projects", operationsHandler.CreateProject)
	api.Get("/operations/overtime", operationsHandler.ListOvertime)
	api.Post("/operations/overtime", operationsHandler.CreateOvertime)

	// --- Onboarding ---
	api.Get("/onboarding/offers", onboardingHandler.ListOffers)
	api.Post("/onboarding/offers", onboardingHandler.CreateOffer)
	api.Get("/onboarding/contracts", onboardingHandler.ListContracts)
	api.Post("/onboarding/contracts", onboardingHandler.CreateContract)

	// --- Accounting (admin, accounting) ---
	api.Get("/accounts", middleware.RequireRole("admin", "accounting"), accountingHandler.ListAccounts)
	api.Post("/accounts", middleware.RequireRole("admin", "accounting"), accountingHandler.CreateAccount)
	api.Get("/journals", middleware.RequireRole("admin", "accounting"), accountingHandler.ListJournals)
	api.Post("/journals", middleware.RequireRole("admin", "accounting"), accountingHandler.CreateJournal)

	// --- Analytics ---
	api.Get("/analytics/hr/dashboard-stats", analyticsHandler.GetHRDashboardStats)
	api.Get("/analytics/hr/payroll-trend", analyticsHandler.GetPayrollTrend)
	api.Get("/analytics/hr/turnover-analysis", analyticsHandler.GetTurnoverAnalysis)
	api.Get("/analytics/hr/recruitment-funnel", analyticsHandler.GetRecruitmentFunnel)
	api.Get("/analytics/hr/leave-balance", analyticsHandler.GetLeaveBalance)
	api.Get("/analytics/hr/attendance-heatmap", analyticsHandler.GetAttendanceHeatmap)
	api.Get("/analytics/accounting/dashboard-stats", middleware.RequireRole("admin", "accounting"), analyticsHandler.GetAccountingDashboardStats)
	api.Get("/analytics/accounting/revenue-expenses", middleware.RequireRole("admin", "accounting"), analyticsHandler.GetRevenueExpenses)
	api.Get("/analytics/accounting/cash-flow", middleware.RequireRole("admin", "accounting"), analyticsHandler.GetCashFlow)
	api.Get("/analytics/accounting/aging-analysis", middleware.RequireRole("admin", "accounting"), analyticsHandler.GetAgingAnalysis)
	api.Get("/analytics/accounting/expense-breakdown", middleware.RequireRole("admin", "accounting"), analyticsHandler.GetExpenseBreakdown)
	api.Get("/analytics/accounting/budget-vs-actual", middleware.RequireRole("admin", "accounting"), analyticsHandler.GetBudgetVsActual)
	api.Get("/analytics/accounting/profit-loss", middleware.RequireRole("admin", "accounting"), analyticsHandler.GetProfitLoss)

	// --- Reports ---
	api.Get("/reports/employees/csv", middleware.RequireRole("admin", "hr"), reportsHandler.EmployeesCSV)
	api.Get("/reports/attendance/csv", middleware.RequireRole("admin", "hr"), reportsHandler.AttendanceCSV)
	api.Get("/reports/payroll/:id/payslips/csv", middleware.RequireRole("admin", "hr"), reportsHandler.PayslipsCSV)
	api.Post("/payslips/:id/email", middleware.RequireRole("admin", "hr"), reportsHandler.EmailPayslip)

	// --- Graceful shutdown ---
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
