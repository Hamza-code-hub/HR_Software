# How to Run Locally (No Docker)

## Prerequisites
- **PostgreSQL**: Must be running on port 5432.
- **Go**: Installed.
- **Flutter**: Installed.

## 1. Backend
1.  Open terminal in `backend` folder.
2.  Run the following command (PowerShell):
    ```powershell
    $env:DATABASE_URL="postgres://postgres:123456@localhost:5432/hr_saas?sslmode=disable"; $env:JWT_SECRET="dev-secret-123"; go run ./cmd/api
    ```

## 2. Frontend
1.  Open terminal in `frontend` folder.
2.  Run:
    ```powershell
    flutter run -d windows
    ```
