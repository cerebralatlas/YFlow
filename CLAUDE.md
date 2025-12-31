# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

i18n-flow is a full-stack internationalization management platform with:
- **admin-backend**: Go/Gin REST API for managing translations, languages, projects, and users
- **admin-frontend**: Vue 3 admin dashboard for platform management
- **cli**: Bun CLI tool for scanning and syncing translations

## Commands

### Backend (Go)

```bash
# Development with hot reload
cd admin-backend && air

# Run tests
go test ./...
```

### Frontend (Vue 3)

```bash
cd admin-frontend

# Install dependencies (use pnpm, not npm)
pnpm install

# Development server
pnpm dev

# Run tests
pnpm test:unit

# Linting
pnpm lint
```

## Architecture

### Backend (Go)

The backend follows a layered architecture with dependency injection via Uber FX:

```
admin-backend/internal/
├── api/           # HTTP handlers, middleware, routes, response utils
├── config/        # Configuration loading
├── container/     # FX dependency injection setup
├── domain/        # Entities and repository interfaces
├── dto/           # Data transfer objects
├── repository/    # Data access layer (GORM with MySQL + Redis caching)
├── service/       # Business logic
└── utils/         # Utilities (JWT, password, datetime)
```

Key patterns:
- Repository layer handles all database operations with Redis caching
- Services contain business logic and call repositories
- Handlers receive HTTP requests, call services, and format responses
- JWT authentication with dual tokens (access + refresh)

### Frontend (Vue 3)

The frontend uses Composition API with:

```
admin-frontend/src/
├── layouts/       # Page layouts (MainLayout)
├── router/        # Vue Router configuration
├── services/      # Axios API client wrappers
├── stores/        # Pinia state management
├── types/         # TypeScript interfaces
└── views/         # Page components
```

Key integrations:
- TanStack Vue Query for data fetching/caching
- Pinia for global state
- Element Plus for UI components

### API Authentication

Two authentication systems:
1. **User Auth**: JWT access + refresh tokens via `/api/login`, `/api/refresh`
2. **CLI Auth**: API Key authentication for `/api/cli/scan`
