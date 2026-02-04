package payroll

import (
	"bytes"
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jung-kurt/gofpdf/v2"
	"hr-saas/internal/repository"
)

// GeneratePayslipPDF returns PDF bytes for the given payslip (tenant-scoped).
func GeneratePayslipPDF(ctx context.Context, pool *pgxpool.Pool, tenantID string, payslip *repository.Payslip) ([]byte, error) {
	run, err := repository.GetPayrollRunByID(ctx, pool, tenantID, payslip.PayrollRunID)
	if err != nil {
		return nil, err
	}
	companyName := "Company"
	if tenant, _ := repository.TenantByID(ctx, pool, run.TenantID); tenant != nil {
		companyName = tenant.CompanyName
	}
	employeeName := payslip.EmployeeID.String()
	if emp, err := repository.GetEmployeeByID(ctx, pool, tenantID, payslip.EmployeeID); err == nil {
		employeeName = emp.Name
	}

	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.AddPage()
	pdf.SetFont("Arial", "B", 16)
	pdf.CellFormat(0, 10, "PAYSLIP", "", 1, "C", false, 0, "")
	pdf.Ln(4)
	pdf.SetFont("Arial", "", 10)
	pdf.CellFormat(0, 6, companyName, "", 1, "L", false, 0, "")
	pdf.CellFormat(0, 6, "Employee: "+employeeName, "", 1, "L", false, 0, "")
	pdf.CellFormat(0, 6, fmt.Sprintf("Period: %d / %d", run.Month, run.Year), "", 1, "L", false, 0, "")
	pdf.Ln(4)
	pdf.SetFont("Arial", "B", 10)
	pdf.CellFormat(40, 6, "Basic Salary", "", 0, "L", false, 0, "")
	pdf.CellFormat(0, 6, fmt.Sprintf("%.2f", payslip.BasicSalary), "", 1, "R", false, 0, "")
	pdf.CellFormat(40, 6, "Gross Salary", "", 0, "L", false, 0, "")
	pdf.CellFormat(0, 6, fmt.Sprintf("%.2f", payslip.GrossSalary), "", 1, "R", false, 0, "")
	pdf.CellFormat(40, 6, "Tax", "", 0, "L", false, 0, "")
	pdf.CellFormat(0, 6, fmt.Sprintf("%.2f", payslip.Tax), "", 1, "R", false, 0, "")
	pdf.CellFormat(40, 6, "Net Salary", "", 0, "L", false, 0, "")
	pdf.CellFormat(0, 6, fmt.Sprintf("%.2f", payslip.NetSalary), "", 1, "R", false, 0, "")

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}
