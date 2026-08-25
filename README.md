<div align="center">

# 🏢 HR • Payroll • Accounting SaaS

### Multi-Tenant Workforce & Financial Management Platform

<p>
A production-oriented <strong>HR, attendance, payroll and accounting SaaS platform</strong>
built with <strong>Go + Fiber</strong>, <strong>PostgreSQL</strong> and a
<strong>Flutter Web/Desktop</strong> client.
</p>

<br>

![Go](https://img.shields.io/badge/Go-Backend-00ADD8?style=for-the-badge\&logo=go\&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-Web_%26_Desktop-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Multi--Tenant-4169E1?style=for-the-badge\&logo=postgresql\&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-Caching_%26_Workers-DC382D?style=for-the-badge\&logo=redis\&logoColor=white)

<br>

![Fiber](https://img.shields.io/badge/API-Fiber-00ACD7?style=flat-square)
![JWT](https://img.shields.io/badge/Auth-JWT-F59E0B?style=flat-square)
![RLS](https://img.shields.io/badge/Security-PostgreSQL_RLS-6366F1?style=flat-square)
![S3](https://img.shields.io/badge/Storage-S3_Compatible-F97316?style=flat-square)
![SaaS](https://img.shields.io/badge/Architecture-Multi--Tenant-8B5CF6?style=flat-square)

<br>

### `HR` • `Attendance` • `Payroll` • `Accounting` • `Reporting` • `Multi-Tenancy`

</div>

---

## ✨ Overview

This project is a full-stack **multi-tenant HR + Payroll + Accounting SaaS platform** designed for software companies and growing organizations that need workforce and financial operations in one system.

It combines:

```text
Flutter Web / Desktop
          │
          ▼
      Go REST API
          │
   ┌──────┼───────────┐
   │      │           │
   ▼      ▼           ▼
  HR   Payroll    Accounting
   │      │           │
   └──────┼───────────┘
          │
          ▼
 PostgreSQL + RLS
          │
    ┌─────┴─────┐
    ▼           ▼
  Redis      S3 Storage
```

The backend owns all business rules while Flutter remains a presentation and interaction layer.

---

# 🚀 Core Modules

<table>
<tr>
<td width="50%">

## 👥 Human Resources

* Employee management
* Tenant-aware user accounts
* Employee profiles
* Organization separation
* Role-aware access
* Soft deletion

</td>

<td width="50%">

## 🕒 Attendance

* Employee check-in
* Employee check-out
* Monthly attendance
* Tenant-scoped attendance records
* Attendance reporting

</td>
</tr>

<tr>
<td>

## 💰 Payroll

* Payroll generation
* Payslip creation
* Payroll locking
* Immutable locked payroll
* PDF payslips
* CSV exports
* Payslip email workflow

</td>

<td>

## 📒 Accounting

* Chart of accounts
* Journal entries
* Balanced accounting lines
* Payroll-to-journal integration
* Financial data protection

</td>
</tr>

<tr>
<td>

## 📊 Reporting

* Employee CSV export
* Attendance reports
* Payroll reports
* Payslip exports
* Server-generated reports

</td>

<td>

## 🏢 Multi-Tenant SaaS

* `tenant_id` isolation
* PostgreSQL Row-Level Security
* Tenant-aware JWT claims
* Tenant-specific data access
* Shared infrastructure with isolated business data

</td>
</tr>
</table>

---

# 🏗️ Architecture

```mermaid
flowchart TB

CLIENT["💻 Flutter Web / Desktop"]

CLIENT --> API["⚡ Go + Fiber REST API"]

API --> AUTH["🔐 Authentication"]
API --> HR["👥 HR"]
API --> ATT["🕒 Attendance"]
API --> PAY["💰 Payroll"]
API --> ACC["📒 Accounting"]
API --> REP["📊 Reporting"]

AUTH --> DB["🐘 PostgreSQL"]
HR --> DB
ATT --> DB
PAY --> DB
ACC --> DB
REP --> DB

DB --> RLS["🛡️ Row-Level Security"]

API --> REDIS["🔴 Redis"]
API --> S3["📦 S3-Compatible Storage"]

RLS --> TENANT["🏢 Tenant Isolation"]
```

---

# 🧱 Engineering Principles

The platform follows several important system-wide rules.

### 01 — Backend Owns Business Logic

```text
Flutter
   │
   │ Requests / Presentation
   ▼
Go API
   │
   │ Validation / Rules / Calculations
   ▼
Database
```

Flutter is intentionally kept thin.

Critical logic such as payroll calculations, tenant enforcement and accounting validation belongs in the backend.

---

### 02 — Every Tenant Record is Isolated

Tenant-aware tables include:

```text
tenant_id
```

Data separation is enforced with **PostgreSQL Row-Level Security (RLS)** rather than relying only on frontend or API filtering.

```text
Tenant A ─────► Tenant A Data
Tenant B ─────► Tenant B Data
Tenant C ─────► Tenant C Data
```

Cross-tenant access should be prevented at both the application and database layers.

---

### 03 — Financial Records Are Never Hard Deleted

Financial records use soft-delete or immutable-history patterns.

```text
Financial Record
      │
      ├── Active
      │
      └── Soft Deleted / Archived
```

Hard deletion should not be used where financial traceability is required.

---

### 04 — Locked Payroll is Immutable

```text
Payroll Draft
      │
      ▼
Payroll Calculation
      │
      ▼
Review
      │
      ▼
LOCK PAYROLL
      │
      ▼
Immutable Payroll Run
      │
      ├── Payslips
      └── Accounting Journal
```

Once a payroll run is locked, it should no longer be modified as an ordinary draft.

---

### 05 — Reports Are Generated Server-Side

Reporting logic remains centralized in the backend.

This improves:

* consistency
* authorization
* tenant isolation
* auditability
* export reliability

---

# 🔐 Authentication

Authentication uses short-lived JWT access tokens with refresh tokens.

```text
Credentials
    │
    ▼
Login
    │
    ▼
Access Token
   15 min
    │
    +
Refresh Token
  168 hours
```

Protected requests use:

```http
Authorization: Bearer <access_token>
```

The token can carry tenant context used by middleware and PostgreSQL RLS enforcement.

---

# 🛡️ Multi-Tenant Security Model

```text
                   Incoming Request
                          │
                          ▼
                    JWT Validation
                          │
                          ▼
                   Extract Tenant ID
                          │
                          ▼
                   Tenant Middleware
                          │
                          ▼
                     DB Context
                          │
                          ▼
              PostgreSQL RLS Policies
                          │
                 ┌────────┴────────┐
                 ▼                 ▼
            Allowed Data       Rejected Data
```

The architecture is designed so tenant isolation does not depend on a single application-layer check.

---

# 📁 Repository Structure

```text
HR-Payroll-Accounting-SaaS/
│
├── backend/
│   │
│   ├── cmd/
│   │   └── api/
│   │       └── Application entrypoint
│   │
│   ├── config/
│   │   └── Environment-based configuration
│   │
│   ├── internal/
│   │   │
│   │   ├── auth/
│   │   │   ├── JWT
│   │   │   ├── password hashing
│   │   │   └── authentication claims
│   │   │
│   │   ├── db/
│   │   │   ├── PostgreSQL pool
│   │   │   └── tenant / RLS context
│   │   │
│   │   ├── handler/
│   │   │   ├── authentication
│   │   │   ├── employees
│   │   │   ├── attendance
│   │   │   └── payroll
│   │   │
│   │   ├── middleware/
│   │   │   ├── JWT middleware
│   │   │   ├── tenant middleware
│   │   │   └── tenant authorization
│   │   │
│   │   ├── payroll/
│   │   │   ├── payroll engine
│   │   │   ├── taxation
│   │   │   └── PDF generation
│   │   │
│   │   └── repository/
│   │       ├── tenants
│   │       ├── users
│   │       ├── employees
│   │       ├── attendance
│   │       └── payroll
│   │
│   └── migrations/
│       ├── PostgreSQL schema
│       └── RLS policies
│
├── frontend/
│   │
│   └── lib/
│       │
│       ├── core/
│       │   ├── API client
│       │   └── routing
│       │
│       ├── data/
│       │   ├── authentication repository
│       │   ├── employees repository
│       │   ├── attendance repository
│       │   └── payroll repository
│       │
│       └── presentation/
│           ├── authentication
│           ├── dashboard
│           ├── employees
│           ├── attendance
│           ├── payroll
│           └── accounting
│
├── scripts/
│   ├── run-backend.ps1
│   ├── run-frontend.ps1
│   ├── run-all.ps1
│   ├── run-backend.sh
│   └── run-frontend.sh
│
├── LOCAL_RUN.md
├── RUN.md
└── README.md
```

---

# 🛠️ Technology Stack

## Backend

| Technology                | Purpose                              |
| ------------------------- | ------------------------------------ |
| **Go 1.21+**              | Backend language                     |
| **Fiber**                 | REST API framework                   |
| **PostgreSQL 16**         | Primary relational database          |
| **PostgreSQL RLS**        | Tenant-level data isolation          |
| **JWT**                   | Authentication                       |
| **Refresh Tokens**        | Session renewal                      |
| **Redis**                 | Caching / background-work foundation |
| **S3-Compatible Storage** | Object and document storage          |

---

## Frontend

| Technology          | Purpose                       |
| ------------------- | ----------------------------- |
| **Flutter**         | Web / Desktop client          |
| **Dart**            | Frontend application language |
| **REST API Client** | Backend communication         |
| **Responsive UI**   | Desktop and web experiences   |

---

# 🚀 Quick Start

## Prerequisites

Install:

```text
Go 1.21+
PostgreSQL 16
Flutter 3.x
Git
```

Optional infrastructure:

```text
Redis
S3-compatible object storage
```

---

# 1️⃣ Clone Repository

```bash
git clone https://github.com/Hamza-code-hub/HR-Payroll-Accounting-SaaS.git

cd HR-Payroll-Accounting-SaaS
```

If the repository is still named `HR_Software`, use its current GitHub URL until it is renamed.

---

# 2️⃣ Database Setup

Create the development database:

```bash
createdb hr_saas
```

Run the initial migration:

```bash
psql hr_saas -f backend/migrations/001_schema.up.sql
```

The migration layer contains the PostgreSQL schema and tenant-isolation policies.

---

# 3️⃣ Backend Setup

Enter the backend directory:

```bash
cd backend
```

Configure environment variables.

### Linux / macOS

```bash
export DATABASE_URL="postgres://postgres:postgres@localhost:5432/hr_saas?sslmode=disable"

export JWT_SECRET="replace-with-a-secure-secret"
```

### Windows PowerShell

```powershell
$env:DATABASE_URL="postgres://postgres:postgres@localhost:5432/hr_saas?sslmode=disable"

$env:JWT_SECRET="replace-with-a-secure-secret"
```

Run the API:

```bash
go run ./cmd/api
```

Default API:

```text
http://localhost:3000
```

---

# ⚡ Local Development Scripts

The repository includes helper scripts for running the project without requiring a containerized development environment.

## Windows / PowerShell

### Backend

```powershell
./scripts/run-backend.ps1
```

### Flutter

```powershell
./scripts/run-frontend.ps1
```

### Backend + Frontend

```powershell
./scripts/run-all.ps1
```

---

## Linux / WSL / macOS

### Backend

```bash
./scripts/run-backend.sh
```

### Frontend

```bash
./scripts/run-frontend.sh
```

The backend helper can initialize the database and apply SQL migration files from:

```text
backend/migrations/*.up.sql
```

depending on the current script configuration.

---

# 🎨 Flutter Frontend

Enter the frontend:

```bash
cd frontend
```

Install dependencies:

```bash
flutter pub get
```

---

## 🌐 Web

```bash
flutter run -d chrome
```

---

## 🪟 Windows

```bash
flutter run -d windows
```

The default backend API is:

```text
http://localhost:3000
```

Update the frontend API configuration when using another backend host.

---

# 🔌 API Overview

## Authentication

### Create Tenant / User

```http
POST /auth/signup
```

Example:

```json
{
  "email": "admin@example.com",
  "password": "strong-password",
  "tenant_name": "Acme Software",
  "subdomain": "acme"
}
```

---

### Login

```http
POST /auth/login
```

Example:

```json
{
  "email": "admin@example.com",
  "password": "strong-password",
  "subdomain": "acme"
}
```

---

### Refresh Session

```http
POST /auth/refresh
```

```json
{
  "refresh_token": "<refresh-token>"
}
```

---

# 🔐 Protected API

All protected endpoints require:

```http
Authorization: Bearer <access_token>
```

---

## 👥 Employees

```http
GET    /api/employees
POST   /api/employees

GET    /api/employees/:id
PUT    /api/employees/:id
DELETE /api/employees/:id
```

Deletion is implemented as **soft deletion**.

---

## 🕒 Attendance

```http
POST /api/attendance/checkin

POST /api/attendance/checkout

GET /api/attendance?month=&year=
```

---

## 💰 Payroll

```http
POST /api/payroll/run

POST /api/payroll/lock

GET  /api/payroll

GET  /api/payroll/:id

GET  /api/payroll/:id/payslips

GET  /api/payslips/:id/pdf
```

Example payroll run:

```json
{
  "month": 8,
  "year": 2026
}
```

Lock payroll:

```json
{
  "id": "<payroll-run-id>"
}
```

---

## 📒 Accounting

### Accounts

```http
GET  /api/accounts

POST /api/accounts
```

### Journal Entries

```http
GET /api/journals?from=&to=

POST /api/journals
```

Journal entries must contain balanced debit and credit lines.

```text
Total Debit
    =
Total Credit
```

---

# 📊 Reports

## Employee CSV

```http
GET /api/reports/employees/csv
```

## Attendance CSV

```http
GET /api/reports/attendance/csv?month=&year=
```

## Payroll Payslip CSV

```http
GET /api/reports/payroll/:id/payslips/csv
```

## Email Payslip

```http
POST /api/payslips/:id/email
```

```json
{
  "email": "employee@example.com"
}
```

---

# 💰 Payroll Lifecycle

```mermaid
flowchart LR

ATT["🕒 Attendance"]

ATT --> CALC["🧮 Payroll Calculation"]

CALC --> DRAFT["📝 Payroll Draft"]

DRAFT --> REVIEW["👀 Review"]

REVIEW --> LOCK["🔒 Lock Payroll"]

LOCK --> PAYSLIP["📄 Payslips"]

LOCK --> JOURNAL["📒 Accounting Journal"]

PAYSLIP --> REPORT["📊 Reports"]
JOURNAL --> REPORT
```

A locked payroll run becomes immutable.

---

# 📒 Accounting Rules

Accounting entries follow double-entry bookkeeping principles.

```text
Journal Entry
│
├── Debit Line(s)
│
└── Credit Line(s)
```

Validation rule:

```text
Σ Debit = Σ Credit
```

Payroll locking can trigger corresponding accounting journal generation.

---

# 🏢 Multi-Tenant Flow

```mermaid
flowchart TB

USER["👤 User"]

USER --> JWT["🔐 JWT"]

JWT --> TENANT["🏢 Tenant Context"]

TENANT --> API["⚡ Go API"]

API --> DB["🐘 PostgreSQL"]

DB --> RLS["🛡️ Row-Level Security"]

RLS --> A["Tenant A Data"]
RLS --> B["Tenant B Data"]
RLS --> C["Tenant C Data"]
```

Each authenticated request carries enough tenant context for the backend and database to isolate access appropriately.

---

# ⚙️ Environment Variables

| Variable                | Description             | Development Default      |
| ----------------------- | ----------------------- | ------------------------ |
| `PORT`                  | API port                | `3000`                   |
| `DATABASE_URL`          | PostgreSQL connection   | `postgres://...`         |
| `JWT_SECRET`            | JWT signing secret      | Change before deployment |
| `JWT_ACCESS_EXPIRE_MIN` | Access-token TTL        | `15`                     |
| `JWT_REFRESH_EXPIRE_H`  | Refresh-token TTL       | `168`                    |
| `REDIS_URL`             | Redis connection        | `redis://localhost:6379` |
| `ENV`                   | Application environment | `development`            |

---

# 🔒 Production Security

Before an internet-facing deployment:

* use a strong random `JWT_SECRET`
* use HTTPS
* store secrets outside source control
* configure PostgreSQL users with minimum required privileges
* verify RLS policies
* restrict database network exposure
* rotate refresh tokens appropriately
* configure Redis authentication/network restrictions
* secure S3-compatible storage
* maintain audit logs
* enable monitoring
* implement automated backups
* test tenant-boundary isolation

Never commit:

```text
.env
private keys
production credentials
database passwords
storage secrets
```

---

# 🧪 Build Progress

The project has been developed around the following sequence:

* [x] Backend authentication
* [x] Tenant middleware
* [x] PostgreSQL RLS
* [x] Employees API
* [x] Attendance API
* [x] Payroll engine
* [x] Payslip PDF generation
* [x] Flutter authentication UI
* [x] Flutter dashboard
* [x] Employee management UI
* [x] Attendance UI
* [x] Payroll UI
* [x] Accounting accounts
* [x] Journal entries
* [x] Payroll → accounting synchronization
* [x] CSV reports
* [x] Payslip email workflow
* [x] Flutter accounting interface
* [x] Local development scripts

---

# 🗺️ Roadmap

Potential next stages include:

### 🏢 HR

* [ ] Leave management
* [ ] Recruitment
* [ ] Performance reviews
* [ ] Employee documents
* [ ] Department analytics

### 💰 Payroll

* [ ] Advanced salary components
* [ ] Tax configuration engine
* [ ] Bonuses and deductions
* [ ] Payroll approval workflow
* [ ] Bank export formats

### 📒 Accounting

* [ ] General ledger
* [ ] Trial balance
* [ ] Profit & loss statement
* [ ] Balance sheet
* [ ] Expense management
* [ ] Accounts receivable
* [ ] Accounts payable

### 📊 Analytics

* [ ] Executive dashboard
* [ ] Workforce analytics
* [ ] Payroll trends
* [ ] Financial reporting
* [ ] Tenant-specific dashboards

### ⚙️ Platform

* [ ] Background jobs
* [ ] Redis queues
* [ ] Object-storage workflows
* [ ] CI/CD
* [ ] Container deployment
* [ ] Automated backups
* [ ] Observability
* [ ] Multi-region deployment

---

# 🎯 Intended Use Cases

| Organization       | Potential Use                     |
| ------------------ | --------------------------------- |
| 💻 Software Houses | HR + payroll + finance            |
| 🏢 Offices         | Employee and salary management    |
| 🚀 Startups        | Unified workforce operations      |
| 🧑‍💼 Agencies     | Employee/payroll administration   |
| 🏭 SMEs            | Workforce + accounting foundation |
| 🌐 SaaS Providers  | Multi-tenant HR platform          |

---

# 🧠 Why Go + Flutter?

## ⚡ Go Backend

Go provides:

* strong performance
* simple deployment
* excellent concurrency
* static binaries
* predictable server behavior
* strong suitability for API services

## 💙 Flutter Frontend

Flutter provides:

* shared UI code
* Web support
* Windows/Desktop support
* responsive interfaces
* consistent design system

Together:

```text
             Flutter
       Web + Desktop UI
             │
             ▼
          REST API
             │
             ▼
           Go
     Business Logic
             │
             ▼
       PostgreSQL
```

---

# 📚 Documentation

Additional project instructions are available in:

```text
LOCAL_RUN.md
RUN.md
```

and the:

```text
scripts/
```

directory.

---

# 🤝 Contributing

Contributions can focus on:

* Go backend architecture
* Flutter UI
* HR workflows
* Payroll
* Accounting
* PostgreSQL
* Row-Level Security
* Reporting
* Testing
* DevOps
* Documentation

Example:

```bash
git checkout -b feature/improvement

git add .

git commit -m "feat: add SaaS improvement"

git push origin feature/improvement
```

---

# ⚠️ Deployment Note

This project contains architecture suitable for a multi-tenant SaaS system, but production deployment still requires environment-specific hardening, operational monitoring, backups, infrastructure configuration and security testing.

Do not assume a development environment is automatically production-safe.

---

<div align="center">

# 🏢 HR • Payroll • Accounting SaaS

## Go × Flutter × PostgreSQL × Multi-Tenant Architecture

### Workforce Operations and Financial Management in One Platform

<br>

![Go](https://img.shields.io/badge/Backend-Go-00ADD8?style=flat-square\&logo=go\&logoColor=white)
![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=flat-square\&logo=flutter\&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-4169E1?style=flat-square\&logo=postgresql\&logoColor=white)
![Redis](https://img.shields.io/badge/Infrastructure-Redis-DC382D?style=flat-square\&logo=redis\&logoColor=white)

<br>

### 👥 HR • 🕒 Attendance • 💰 Payroll • 📒 Accounting • 📊 Reports

<br>

**A scalable foundation for modern workforce and financial operations.**

</div>
