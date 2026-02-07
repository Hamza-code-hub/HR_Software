# How to run HR & Accounting SaaS
> **Note**: For running locally without Docker, see [LOCAL_RUN.md](LOCAL_RUN.md).

## Project overview

- **Backend** (Go/Fiber): REST API with JWT auth, multi-tenant (PostgreSQL + RLS). Handles auth, employees, attendance, payroll, accounting, reports.
- **Frontend** (Flutter): Web + Windows app. Login/signup, dashboard, employees (grid), attendance, payroll, accounting. All logic is in the backend; Flutter only calls APIs.

## 1. Database (required for backend)

**Option A – Docker (recommended)**

```bash
docker-compose up -d db
# Then run migrations (see below).
```

**Option B – Local PostgreSQL**

- Install PostgreSQL 16, create database: `createdb hr_saas`
- Run migrations from `backend/migrations/` in order:
  - `001_schema.up.sql`
  - `002_employee_salary.up.sql`

## 2. Backend

```bash
cd backend
set DATABASE_URL=postgres://postgres:postgres@localhost:5432/hr_saas?sslmode=disable
set JWT_SECRET=your-secret
go run ./cmd/api
```

API will be at **http://localhost:3000**. CORS is enabled for `http://localhost:*` and `http://127.0.0.1:*` so Flutter web can call it.

## 3. Flutter

```bash
cd frontend
flutter pub get
```

**Web (Chrome):**
```bash
flutter run -d chrome
```

**Windows desktop:**  
You must pass `-d windows` so Flutter targets the desktop app instead of the browser.
```bash
flutter run -d windows
```
A desktop window will open (frontend.exe). If nothing appears, check the taskbar or behind other windows.

**If "No devices found" for Windows:**  
- Run `flutter doctor -v` and fix any issues under "Visual Studio - develop Windows apps".  
- Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the "Desktop development with C++" workload.

## 4. First use

1. Open the app → **Create account** (signup with email, password, company name).
2. You are logged in and see the **Dashboard** (Employees, Attendance, Payroll, Accounting).
3. Add employees (with optional basic salary for payroll), then use Attendance, Payroll, and Accounting as needed.

## Troubleshooting

- **Flutter: “Connection refused” or network errors**  
  Start the backend (step 2) and ensure nothing else is using port 3000.

- **Backend: “database connection” error**  
  Start PostgreSQL and run the migrations (step 1).

- **Docker not running**  
  Start Docker Desktop, then run `docker-compose up -d db`.
