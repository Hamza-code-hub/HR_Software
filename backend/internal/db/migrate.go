package db

import (
    "context"
    "io/ioutil"
    "path/filepath"
    "sort"
    "strings"

    "github.com/jackc/pgx/v5/pgxpool"
)

// EnsureDBAndMigrate ensures the target database exists and runs all *.up.sql
// migrations found in migrationsDir. migrationsDir should be relative to the
// backend working directory (default: "migrations").
func EnsureDBAndMigrate(ctx context.Context, connString, migrationsDir string) error {
    if migrationsDir == "" {
        migrationsDir = "migrations"
    }

    // Parse config to extract database name and connect params
    cfg, err := pgxpool.ParseConfig(connString)
    if err != nil {
        return err
    }

    targetDB := cfg.ConnConfig.Database
    if targetDB == "" {
        targetDB = "postgres"
    }

    // Connect to admin DB (postgres) to create target database if missing
    adminCfg := *cfg
    adminCfg.ConnConfig.Database = "postgres"

    adminPool, err := pgxpool.NewWithConfig(ctx, &adminCfg)
    if err != nil {
        return err
    }
    defer adminPool.Close()

    var exists bool
    row := adminPool.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname=$1)", targetDB)
    if err := row.Scan(&exists); err != nil {
        return err
    }
    if !exists {
        if _, err := adminPool.Exec(ctx, "CREATE DATABASE "+pgIdentifier(targetDB)); err != nil {
            return err
        }
    }

    // Now connect to target database and run migrations
    targetCfg := *cfg
    targetCfg.ConnConfig.Database = targetDB
    pool, err := pgxpool.NewWithConfig(ctx, &targetCfg)
    if err != nil {
        return err
    }
    defer pool.Close()

    // Read migration files
    files, err := ioutil.ReadDir(migrationsDir)
    if err != nil {
        return err
    }
    var ups []string
    for _, f := range files {
        if f.IsDir() {
            continue
        }
        name := f.Name()
        if strings.HasSuffix(name, ".up.sql") {
            ups = append(ups, filepath.Join(migrationsDir, name))
        }
    }
    sort.Strings(ups)

    if len(ups) == 0 {
        return nil
    }

    tx, err := pool.Begin(ctx)
    if err != nil {
        return err
    }
    defer func() {
        _ = tx.Rollback(ctx)
    }()

    for _, path := range ups {
        b, err := ioutil.ReadFile(path)
        if err != nil {
            return err
        }
        sql := string(b)
        if strings.TrimSpace(sql) == "" {
            continue
        }
        if _, err := tx.Exec(ctx, sql); err != nil {
            return err
        }
    }

    if err := tx.Commit(ctx); err != nil {
        return err
    }

    return nil
}

// pgIdentifier returns a safely quoted identifier for CREATE DATABASE.
func pgIdentifier(name string) string {
    return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
}
