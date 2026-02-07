# HR & Accounting SaaS

Multi-tenant HR + Payroll + Accounting system for Pakistani software houses.

- **Backend**: Go (Fiber), JWT + Refresh Token, PostgreSQL (RLS), Redis, S3-compatible storage
- **Frontend**: Flutter Web/Desktop (UI only; all logic in backend)
- **MVP**: 12–16 weeks

## Global rules

- All business logic in backend; frontend is UI only
- Every tenant table has `tenant_id`; multi-tenancy enforced with RLS
- No hard delete on financial data (soft delete only)
- Payroll runs immutable once locked
- Reports generated server-side

## Quick start (backend)

### Prerequisites

- Go 1.21+
- PostgreSQL 16
- (Optional) Docker & Docker Compose

### Local run

1. Create DB and run migrations:

   ```bash
   createdb hr_saas
   psql hr_saas -f backend/migrations/001_schema.up.sql
   ```

2. Run API:

   ```bash
   cd backend
   export DATABASE_URL="postgres://postgres:postgres@localhost:5432/hr_saas?sslmode=disable"
   export JWT_SECRET="your-secret"
   go run ./cmd/api
   ```

   API: `http://localhost:3000`

### Run locally without Docker (recommended)

- Scripts are provided in the `scripts/` directory to run backend and frontend without Docker.

- Windows (PowerShell):

  ```powershell
  ./scripts/run-backend.ps1    # starts backend, runs migrations
  ./scripts/run-frontend.ps1   # starts Flutter frontend (chrome)
  ./scripts/run-all.ps1        # starts backend in background + frontend
  ```

- Unix / WSL / macOS (bash):

  ```bash
  ./scripts/run-backend.sh
  ./scripts/run-frontend.sh
  ```

Notes:

- The backend will create the database (user must have permission) and run the SQL files in `backend/migrations/*.up.sql`.
- Configure `DATABASE_URL` and `JWT_SECRET` as needed before running.
- If you prefer Docker, the Compose files were removed to simplify local development; run Postgres + Redis locally or via a service.

### Docker

```bash
docker-compose up -d
# API: http://localhost:3000
# DB: localhost:5432 (postgres/postgres, hr_saas)
# Redis: localhost:6379
```

## API (MVP)

### Auth (no JWT)

- `POST /auth/signup` — body: `{ "email", "password", "tenant_name", "subdomain?" }`
- `POST /auth/login` — body: `{ "email", "password", "tenant_id?" | "subdomain?" }`
- `POST /auth/refresh` — body: `{ "refresh_token" }`

### Protected (Header: `Authorization: Bearer <access_token>`)

- **Employees**: `GET/POST /api/employees`, `GET/PUT/DELETE /api/employees/:id` (soft delete)
- **Attendance**: `POST /api/attendance/checkin`, `POST /api/attendance/checkout`, `GET /api/attendance?month=&year=`
- **Payroll**: `POST /api/payroll/run` (body: `{ "month", "year" }`), `POST /api/payroll/lock` (body: `{ "id" }`), `GET /api/payroll`, `GET /api/payroll/:id`, `GET /api/payroll/:id/payslips`, `GET /api/payslips/:id/pdf`
- **Accounting**: `GET /api/accounts`, `POST /api/accounts`, `GET /api/journals?from=&to=`, `POST /api/journals` (balanced lines)
- **Reports**: `GET /api/reports/employees/csv`, `GET /api/reports/attendance/csv?month=&year=`, `GET /api/reports/payroll/:id/payslips/csv`, `POST /api/payslips/:id/email` (body: `{"email"}`)

### Flutter (Web / Desktop)

```bash
cd frontend
flutter pub get
# Web
flutter run -d chrome
# Windows
flutter run -d windows
```

Set API base in code or env (default `http://localhost:3000`).

## Project layout

```
backend/
  cmd/api/          # Entrypoint
  config/           # Env-based config
  internal/
    auth/           # JWT, hash, claims
    db/             # Pool, WithTenant (RLS)
    handler/        # Auth, Employees, Attendance, Payroll
    middleware/     # JWT, TenantFromJWT, RequireTenant
    payroll/        # Engine (tax, run, PDF)
    repository/     # Tenants, Users, Employees, Attendance, Payroll
  migrations/       # PostgreSQL schema + RLS
frontend/           # Flutter Web + Desktop
  lib/
    core/           # API client, router
    data/           # Repositories (auth, employees, attendance, payroll)
    presentation/   # auth, dashboard, employees, attendance, payroll
docker-compose.yml
```

## Build order (implemented)

1. Backend auth + tenant middleware
2. Employees API
3. Attendance API
4. Payroll engine + Payslip PDF
5. Flutter UI (auth, dashboard, employees, attendance, payroll)
6. Accounting (accounts, journals; payroll lock → journal sync)
7. Reports (CSV export, email payslip stub)
8. CI (GitHub Actions: backend build/test, Docker build, Flutter build)
9. Flutter Accounting screen (accounts list, journal entries list, add account)

## Environment

| Variable              | Description                  | Default (dev)           |
| --------------------- | ---------------------------- | ----------------------- |
| PORT                  | API port                     | 3000                    |
| DATABASE_URL          | PostgreSQL connection string | postgres://...          |
| JWT_SECRET            | JWT signing secret           | change-me-in-production |
| JWT_ACCESS_EXPIRE_MIN | Access token TTL (min)       | 15                      |
| JWT_REFRESH_EXPIRE_H  | Refresh token TTL (hours)    | 168                     |
| REDIS_URL             | Redis (for workers later)    | redis://localhost:6379  |
| ENV                   | development / production     | development             |
