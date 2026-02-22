package config

import (
	"os"
	"strconv"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Redis    RedisConfig
	S3       S3Config
}

type ServerConfig struct {
	Port string
	Env  string
}

type DatabaseConfig struct {
	URL string
}

type JWTConfig struct {
	Secret          string
	AccessExpireMin int
	RefreshExpireH  int
}

type RedisConfig struct {
	URL string
}

type S3Config struct {
	Endpoint  string
	Bucket    string
	AccessKey string
	SecretKey string
}

func Load() *Config {
	accessMin := 15
	if v := os.Getenv("JWT_ACCESS_EXPIRE_MIN"); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			accessMin = i
		}
	}
	refreshH := 168 // 7 days
	if v := os.Getenv("JWT_REFRESH_EXPIRE_H"); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			refreshH = i
		}
	}
	return &Config{
		Server: ServerConfig{
			Port: getEnv("PORT", "3000"),
			Env:  getEnv("ENV", "development"),
		},
		Database: DatabaseConfig{
			URL: getEnv("DATABASE_URL", "postgres://postgres:123456@localhost:5432/hr_saas?sslmode=disable"),
		},
		JWT: JWTConfig{
			Secret:          getEnv("JWT_SECRET", "dev-secret-123"),
			AccessExpireMin: accessMin,
			RefreshExpireH:  refreshH,
		},
		Redis: RedisConfig{
			URL: getEnv("REDIS_URL", "redis://localhost:6379"),
		},
		S3: S3Config{
			Endpoint:  getEnv("S3_ENDPOINT", ""),
			Bucket:    getEnv("S3_BUCKET", "hr-saas"),
			AccessKey: getEnv("S3_ACCESS_KEY", ""),
			SecretKey: getEnv("S3_SECRET_KEY", ""),
		},
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
