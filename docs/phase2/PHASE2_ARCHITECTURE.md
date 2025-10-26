# Phase 2 Architecture: Query Service + Home Dashboard

**Version:** 1.0
**Date:** October 22, 2025
**Status:** Implementation Ready
**Estimated Duration:** 3 weeks

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture Overview](#system-architecture-overview)
3. [Backend: Query Service Architecture](#backend-query-service-architecture)
4. [Frontend: Dashboard Architecture](#frontend-dashboard-architecture)
5. [Communication Patterns](#communication-patterns)
6. [Database Architecture](#database-architecture)
7. [Security Architecture](#security-architecture)
8. [Deployment Architecture](#deployment-architecture)
9. [Testing Strategy](#testing-strategy)
10. [Implementation Roadmap](#implementation-roadmap)
11. [Architecture Decision Records](#architecture-decision-records)

---

## Executive Summary

Phase 2 builds upon the completed Phase 1 backend services (Gateway, Ingestion, Processing) to deliver:

1. **Query Service** - A high-performance API service for aggregated metrics and dashboard data with Redis caching
2. **Home Dashboard** - Real-time frontend interface with authentication, KPIs, alerts, and activity feeds
3. **Multi-Service Integration** - Seamless communication between Gateway, Query Service, and Frontend

### Key Objectives

- Provide sub-200ms response times for dashboard queries through aggressive caching
- Support real-time data updates with 5-minute cache TTL
- Enable secure authentication flow from frontend through Gateway to Query Service
- Deliver production-ready home dashboard with 4 KPI cards, alerts feed, and activity stream
- Achieve 100% test coverage for critical paths (authentication, query endpoints, caching)

### Success Metrics

| Metric | Target |
|--------|--------|
| Query Response Time (P95) | < 200ms |
| Cache Hit Rate | > 80% |
| Dashboard Load Time | < 2s |
| Test Coverage | > 90% |
| API Endpoint Availability | 99.9% |

---

## System Architecture Overview

### Phase 2 Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Port 3000)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Login/Register│  │ Home Dashboard│  │ Protected Routes    │  │
│  │   Pages      │  │   (Real Data) │  │   (Phase 3)         │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────────────┘  │
│         │                  │                                     │
│         └──────────────────┴─────────────────────────────────────┤
│                            │                                     │
│                    React Query + Axios                          │
│                            │                                     │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                             │ HTTP/HTTPS
                             │ JWT Bearer Token
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API GATEWAY (Port 8000)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ JWT Auth     │  │ Rate Limiting│  │ Request Routing      │  │
│  │ Middleware   │  │  (Redis)     │  │  /api/v1/*          │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────────────┘  │
│         │                  │                  │                  │
│         └──────────────────┴──────────────────┼──────────────────┤
│                                               │                  │
└───────────────────────────────────────────────┼──────────────────┘
                                                │
                    ┌───────────────────────────┼───────────────┐
                    │                           │               │
                    ▼                           ▼               ▼
         ┌──────────────────┐      ┌─────────────────┐  ┌────────────┐
         │ QUERY SERVICE    │      │  INGESTION      │  │ PROCESSING │
         │  (Port 8003)     │      │  (Port 8001)    │  │  SERVICE   │
         │                  │      │                 │  │            │
         │ ┌──────────────┐ │      │  (Phase 1)      │  │ (Phase 1)  │
         │ │ Home KPIs    │ │      │                 │  │            │
         │ │ Alerts API   │ │      │                 │  │            │
         │ │ Activity API │ │      │                 │  │            │
         │ │ Trace Queries│ │      │                 │  │            │
         │ └──────┬───────┘ │      └─────────────────┘  └────────────┘
         │        │         │               │                  │
         └────────┼─────────┘               │                  │
                  │                         │                  │
                  │ Redis Cache (5min TTL) │                  │
                  ▼                         ▼                  ▼
         ┌─────────────────────────────────────────────────────────┐
         │                   REDIS (Port 6379)                      │
         │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
         │  │ Query Cache  │  │ Rate Limits  │  │ Streams Queue │ │
         │  │  (5min TTL)  │  │              │  │               │ │
         │  └──────────────┘  └──────────────┘  └───────────────┘ │
         └─────────────────────────────────────────────────────────┘
                  │
                  │ Read Queries
                  ▼
         ┌─────────────────────────────────────────────────────────┐
         │             TimescaleDB (Port 5432)                      │
         │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
         │  │ traces       │  │ traces_hourly│  │ traces_daily  │ │
         │  │ (Hypertable) │  │ (Cont. Agg)  │  │ (Cont. Agg)   │ │
         │  └──────────────┘  └──────────────┘  └───────────────┘ │
         └─────────────────────────────────────────────────────────┘
                  ▲
                  │ Read User Data
                  │
         ┌─────────────────────────────────────────────────────────┐
         │             PostgreSQL (Port 5433)                       │
         │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
         │  │ users        │  │ workspaces   │  │ api_keys      │ │
         │  └──────────────┘  └──────────────┘  └───────────────┘ │
         └─────────────────────────────────────────────────────────┘
```

### Service Communication Matrix

| From Service | To Service | Protocol | Purpose | Auth Method |
|--------------|-----------|----------|---------|-------------|
| Frontend | Gateway | HTTP/HTTPS | All API calls | JWT Bearer |
| Gateway | Query Service | HTTP | Dashboard queries | Internal |
| Gateway | Ingestion | HTTP | Trace ingestion | Internal |
| Query Service | TimescaleDB | PostgreSQL | Read traces/metrics | Connection Pool |
| Query Service | PostgreSQL | PostgreSQL | Read user/workspace | Connection Pool |
| Query Service | Redis | Redis Protocol | Cache get/set | Password Auth |
| Processing | TimescaleDB | PostgreSQL | Write traces | Connection Pool |
| Processing | Redis | Redis Protocol | Stream consumption | Password Auth |

---

## Backend: Query Service Architecture

### 3.1 Service Overview

**Port:** 8003
**Purpose:** High-performance read API for dashboard metrics with intelligent caching
**Technology Stack:**
- FastAPI 0.104.1
- asyncpg 0.29.0 (async PostgreSQL/TimescaleDB driver)
- redis 5.0.1 (caching layer)
- pydantic 2.5.0 (data validation)

### 3.2 Directory Structure

```
backend/query/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI application entry point
│   ├── config.py                  # Environment configuration
│   ├── database.py                # Database connection pool management
│   ├── cache.py                   # Redis caching layer with TTL
│   ├── queries.py                 # SQL query builders and executors
│   ├── models.py                  # Pydantic response models (DONE)
│   │
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── home.py                # Home dashboard KPIs, alerts, activity
│   │   ├── traces.py              # Trace listing and detail queries
│   │   └── metrics.py             # Generic metrics aggregations
│   │
│   └── utils/
│       ├── __init__.py
│       ├── time_ranges.py         # Time range parsing (24h, 7d, 30d)
│       └── formatters.py          # Data formatting utilities
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py                # Pytest fixtures
│   ├── test_home_kpis.py          # 5 tests
│   ├── test_traces.py             # 7 tests
│   └── test_cache.py              # 3 tests
│
├── Dockerfile                     # Production Docker image
├── requirements.txt               # Python dependencies
└── .env.example                   # Environment variables template
```

### 3.3 API Endpoints Specification

#### 3.3.1 Home Dashboard Endpoints

**GET /api/v1/metrics/home-kpis**

Query Parameters:
- `range`: Time range (1h, 24h, 7d, 30d, custom) - Default: 24h
- `workspace_id`: UUID (optional, extracted from JWT)

Response Schema:
```json
{
  "total_requests": {
    "value": 12543,
    "change": 12.5,
    "change_label": "vs last 24h",
    "trend": "normal"
  },
  "avg_latency_ms": {
    "value": 1234,
    "change": -5.2,
    "change_label": "vs last 24h",
    "trend": "inverse"
  },
  "error_rate": {
    "value": 1.5,
    "change": -0.3,
    "change_label": "vs last 24h",
    "trend": "inverse"
  },
  "total_cost_usd": {
    "value": 234.56,
    "change": 8.1,
    "change_label": "vs last 24h",
    "trend": "normal"
  },
  "avg_quality_score": {
    "value": 87.3,
    "change": 2.1,
    "change_label": "vs last 24h",
    "trend": "normal"
  }
}
```

Cache Strategy: 5-minute TTL, key pattern: `home_kpis:{workspace_id}:{range}`

---

**GET /api/v1/alerts/recent**

Query Parameters:
- `limit`: Number of alerts (1-100) - Default: 10
- `severity`: Filter by severity (info, warning, critical) - Optional
- `workspace_id`: UUID (optional, extracted from JWT)

Response Schema:
```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "High Error Rate Detected",
      "description": "Error rate increased to 5.2% in the last hour",
      "severity": "warning",
      "metric_value": 5.2,
      "created_at": "2025-10-22T10:30:00Z"
    }
  ],
  "total": 42
}
```

Cache Strategy: 1-minute TTL, key pattern: `alerts:recent:{workspace_id}:{limit}:{severity}`

---

**GET /api/v1/activity/stream**

Query Parameters:
- `limit`: Number of activities (1-100) - Default: 50
- `workspace_id`: UUID (optional, extracted from JWT)

Response Schema:
```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "workspace_id": "550e8400-e29b-41d4-a716-446655440000",
      "trace_id": "trace_abc123",
      "agent_id": "support-bot-v1",
      "action": "trace_ingested",
      "status": "success",
      "timestamp": "2025-10-22T10:35:22Z",
      "metadata": {
        "latency_ms": 1234,
        "model": "gpt-4-turbo"
      }
    }
  ],
  "total": 150
}
```

Cache Strategy: 30-second TTL, key pattern: `activity:stream:{workspace_id}:{limit}`

---

#### 3.3.2 Trace Query Endpoints

**GET /api/v1/traces**

Query Parameters:
- `workspace_id`: UUID (required)
- `range`: Time range (1h, 24h, 7d, 30d, custom)
- `agent_id`: Filter by agent (optional)
- `status`: Filter by status (success, error, timeout) (optional)
- `limit`: Results per page (1-100) - Default: 50
- `page`: Page number - Default: 1

Response Schema: PaginatedResponse[Trace]

Cache Strategy: 2-minute TTL, key pattern: `traces:list:{workspace_id}:{filters_hash}`

---

**GET /api/v1/traces/{trace_id}**

Path Parameters:
- `trace_id`: Trace identifier

Response Schema: TraceDetail (full trace with input/output)

Cache Strategy: 10-minute TTL, key pattern: `trace:detail:{trace_id}`

---

### 3.4 Caching Architecture

**Redis Cache Layer Implementation:**

```python
# app/cache.py
import redis.asyncio as redis
import json
from typing import Optional, Any
from datetime import timedelta

class CacheManager:
    def __init__(self, redis_url: str):
        self.redis = redis.from_url(redis_url, decode_responses=True)

    async def get(self, key: str) -> Optional[Any]:
        """Get cached value, returns None if not found"""
        value = await self.redis.get(key)
        if value:
            return json.loads(value)
        return None

    async def set(self, key: str, value: Any, ttl_seconds: int):
        """Set cached value with TTL"""
        await self.redis.setex(
            key,
            timedelta(seconds=ttl_seconds),
            json.dumps(value, default=str)
        )

    async def delete(self, pattern: str):
        """Delete keys matching pattern"""
        keys = await self.redis.keys(pattern)
        if keys:
            await self.redis.delete(*keys)

    async def invalidate_workspace(self, workspace_id: str):
        """Invalidate all cached data for a workspace"""
        patterns = [
            f"home_kpis:{workspace_id}:*",
            f"alerts:recent:{workspace_id}:*",
            f"activity:stream:{workspace_id}:*",
            f"traces:list:{workspace_id}:*"
        ]
        for pattern in patterns:
            await self.delete(pattern)
```

**Cache TTL Strategy:**

| Cache Type | TTL | Rationale |
|-----------|-----|-----------|
| Home KPIs | 5 minutes | Balance freshness vs load |
| Alerts | 1 minute | Near real-time alerting |
| Activity Stream | 30 seconds | Recent activity critical |
| Trace List | 2 minutes | Moderate freshness need |
| Trace Detail | 10 minutes | Immutable once created |

---

### 3.5 Database Query Optimization

**Connection Pooling Configuration:**

```python
# app/database.py
import asyncpg
from typing import Optional

class DatabaseManager:
    def __init__(self):
        self.timescale_pool: Optional[asyncpg.Pool] = None
        self.postgres_pool: Optional[asyncpg.Pool] = None

    async def connect_timescale(self, url: str):
        """Create connection pool to TimescaleDB"""
        self.timescale_pool = await asyncpg.create_pool(
            url,
            min_size=5,
            max_size=20,
            command_timeout=10,
            max_queries=50000,
            max_inactive_connection_lifetime=300
        )

    async def connect_postgres(self, url: str):
        """Create connection pool to PostgreSQL"""
        self.postgres_pool = await asyncpg.create_pool(
            url,
            min_size=2,
            max_size=10,
            command_timeout=5
        )
```

**Optimized SQL Queries:**

```python
# app/queries.py
from typing import Dict, Any, List
import asyncpg

class QueryBuilder:
    """SQL query builder using TimescaleDB continuous aggregates"""

    @staticmethod
    async def get_home_kpis(
        pool: asyncpg.Pool,
        workspace_id: str,
        range_hours: int
    ) -> Dict[str, Any]:
        """
        Get home dashboard KPIs using continuous aggregates for performance.
        Uses traces_hourly view to avoid scanning raw traces table.
        """
        query = """
        WITH current_period AS (
            SELECT
                COUNT(*) as total_requests,
                AVG(avg_latency_ms) as avg_latency,
                SUM(error_count)::float / NULLIF(SUM(request_count), 0) * 100 as error_rate,
                SUM(total_cost_usd) as total_cost
            FROM traces_hourly
            WHERE workspace_id = $1
              AND hour >= NOW() - INTERVAL '1 hour' * $2
        ),
        previous_period AS (
            SELECT
                COUNT(*) as total_requests,
                AVG(avg_latency_ms) as avg_latency,
                SUM(error_count)::float / NULLIF(SUM(request_count), 0) * 100 as error_rate,
                SUM(total_cost_usd) as total_cost
            FROM traces_hourly
            WHERE workspace_id = $1
              AND hour >= NOW() - INTERVAL '1 hour' * ($2 * 2)
              AND hour < NOW() - INTERVAL '1 hour' * $2
        )
        SELECT
            c.total_requests as curr_requests,
            p.total_requests as prev_requests,
            c.avg_latency as curr_latency,
            p.avg_latency as prev_latency,
            c.error_rate as curr_error_rate,
            p.error_rate as prev_error_rate,
            c.total_cost as curr_cost,
            p.total_cost as prev_cost
        FROM current_period c, previous_period p;
        """

        async with pool.acquire() as conn:
            row = await conn.fetchrow(query, workspace_id, range_hours)
            return dict(row) if row else {}

    @staticmethod
    async def get_recent_alerts(
        pool: asyncpg.Pool,
        workspace_id: str,
        limit: int,
        severity: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get recent alerts with optional severity filter"""
        query = """
        SELECT
            id,
            workspace_id,
            title,
            description,
            severity,
            metric_value,
            created_at
        FROM alerts
        WHERE workspace_id = $1
        """

        params = [workspace_id]

        if severity:
            query += " AND severity = $2"
            params.append(severity)

        query += " ORDER BY created_at DESC LIMIT $" + str(len(params) + 1)
        params.append(limit)

        async with pool.acquire() as conn:
            rows = await conn.fetch(query, *params)
            return [dict(row) for row in rows]

    @staticmethod
    async def get_activity_stream(
        pool: asyncpg.Pool,
        workspace_id: str,
        limit: int
    ) -> List[Dict[str, Any]]:
        """
        Get recent activity by querying recent traces.
        Maps traces to activity items.
        """
        query = """
        SELECT
            trace_id,
            agent_id,
            timestamp,
            status,
            latency_ms,
            model,
            cost_usd
        FROM traces
        WHERE workspace_id = $1
          AND timestamp >= NOW() - INTERVAL '1 hour'
        ORDER BY timestamp DESC
        LIMIT $2
        """

        async with pool.acquire() as conn:
            rows = await conn.fetch(query, workspace_id, limit)
            # Transform to activity format
            activities = []
            for row in rows:
                activities.append({
                    'trace_id': row['trace_id'],
                    'agent_id': row['agent_id'],
                    'action': 'trace_ingested',
                    'status': row['status'],
                    'timestamp': row['timestamp'],
                    'metadata': {
                        'latency_ms': row['latency_ms'],
                        'model': row['model'],
                        'cost_usd': float(row['cost_usd']) if row['cost_usd'] else None
                    }
                })
            return activities
```

---

### 3.6 Error Handling Strategy

```python
# app/routes/home.py
from fastapi import APIRouter, HTTPException, Depends, status
from app.cache import CacheManager
from app.queries import QueryBuilder
from app.models import HomeKPIs, KPIMetric

router = APIRouter(prefix="/api/v1/metrics", tags=["metrics"])

@router.get("/home-kpis", response_model=HomeKPIs)
async def get_home_kpis(
    range: str = "24h",
    cache: CacheManager = Depends(get_cache),
    db: DatabaseManager = Depends(get_database)
):
    """
    Get home dashboard KPIs with caching.

    Error Handling:
    - 400: Invalid time range
    - 500: Database connection error
    - 503: Cache unavailable (fallback to database)
    """
    try:
        # Parse time range
        range_hours = parse_time_range(range)
        if range_hours is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid time range: {range}"
            )

        # Try cache first
        cache_key = f"home_kpis:{workspace_id}:{range}"
        cached = await cache.get(cache_key)
        if cached:
            return HomeKPIs(**cached)

        # Query database
        kpi_data = await QueryBuilder.get_home_kpis(
            db.timescale_pool,
            workspace_id,
            range_hours
        )

        # Calculate percentage changes
        result = calculate_kpi_metrics(kpi_data)

        # Cache result (fire and forget, don't block on cache failure)
        try:
            await cache.set(cache_key, result.dict(), ttl_seconds=300)
        except Exception as cache_error:
            # Log but don't fail request
            logger.warning(f"Cache set failed: {cache_error}")

        return result

    except asyncpg.exceptions.PostgresError as db_error:
        logger.error(f"Database error: {db_error}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database query failed"
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
```

---

## Frontend: Dashboard Architecture

### 4.1 Frontend Technology Stack

**Core Framework:**
- Next.js 14 (App Router)
- React 18
- TypeScript (strict mode)

**State Management:**
- TanStack Query (React Query) 5.x - Server state management
- React Context - Auth state
- Local Storage - Token persistence

**UI Components:**
- shadcn/ui - Component library
- Tailwind CSS - Styling
- lucide-react - Icons

**HTTP Client:**
- Axios - API communication

### 4.2 Authentication Architecture

**Authentication Flow:**

```
┌──────────┐                                    ┌──────────┐
│ Browser  │                                    │ Gateway  │
└────┬─────┘                                    └────┬─────┘
     │                                                │
     │  1. POST /api/v1/auth/login                   │
     │    { email, password }                         │
     ├──────────────────────────────────────────────>│
     │                                                │
     │  2. Validate credentials (PostgreSQL)          │
     │     Generate JWT token                         │
     │<──────────────────────────────────────────────┤
     │    { access_token, expires_in }                │
     │                                                │
     │  3. Store token in localStorage                │
     │     Set auth context                           │
     │                                                │
     │  4. Redirect to /dashboard                     │
     │                                                │
     │  5. GET /api/v1/metrics/home-kpis              │
     │     Authorization: Bearer <token>              │
     ├──────────────────────────────────────────────>│
     │                                                │
     │  6. Verify JWT, extract workspace_id           │
     │     Forward to Query Service                   │
     │<──────────────────────────────────────────────┤
     │    { total_requests: {...}, ... }              │
     │                                                │
```

**Auth Context Implementation:**

```typescript
// app/contexts/AuthContext.tsx
'use client'

import { createContext, useContext, useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import apiClient from '@/lib/api-client'

interface User {
  id: string
  email: string
  full_name: string
  workspace_id: string
}

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  register: (data: RegisterData) => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()

  // Check for existing token on mount
  useEffect(() => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      // Verify token and get user info
      fetchCurrentUser()
    } else {
      setLoading(false)
    }
  }, [])

  const fetchCurrentUser = async () => {
    try {
      const response = await apiClient.get('/api/v1/auth/me')
      setUser(response.data)
    } catch (error) {
      // Token invalid, clear it
      localStorage.removeItem('auth_token')
    } finally {
      setLoading(false)
    }
  }

  const login = async (email: string, password: string) => {
    const response = await apiClient.post('/api/v1/auth/login', {
      email,
      password
    })

    const { access_token, expires_in } = response.data
    localStorage.setItem('auth_token', access_token)

    await fetchCurrentUser()
    router.push('/dashboard')
  }

  const logout = () => {
    localStorage.removeItem('auth_token')
    setUser(null)
    router.push('/login')
  }

  const register = async (data: RegisterData) => {
    await apiClient.post('/api/v1/auth/register', data)
    // Auto-login after registration
    await login(data.email, data.password)
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, register }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}
```

---

### 4.3 Login/Register Pages

**File Structure:**

```
frontend/app/
├── login/
│   └── page.tsx                    # Login page
├── register/
│   └── page.tsx                    # Registration page
└── dashboard/
    └── page.tsx                    # Protected dashboard (updated)
```

**Login Page Implementation:**

```typescript
// app/login/page.tsx
'use client'

import { useState } from 'react'
import { useAuth } from '@/app/contexts/AuthContext'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import Link from 'next/link'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(email, password)
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl font-bold">Sign In</CardTitle>
          <CardDescription>
            Enter your credentials to access the dashboard
          </CardDescription>
        </CardHeader>
        <CardContent>
          {error && (
            <Alert variant="destructive" className="mb-4">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={loading}
                minLength={8}
              />
            </div>

            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? 'Signing in...' : 'Sign In'}
            </Button>
          </form>

          <div className="mt-4 text-center text-sm">
            Don't have an account?{' '}
            <Link href="/register" className="text-primary hover:underline">
              Sign up
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
```

**Register Page Implementation:**

```typescript
// app/register/page.tsx
'use client'

import { useState } from 'react'
import { useAuth } from '@/app/contexts/AuthContext'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import Link from 'next/link'

export default function RegisterPage() {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    full_name: '',
    workspace_name: ''
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { register } = useAuth()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    // Validation
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match')
      return
    }

    setLoading(true)

    try {
      await register({
        email: formData.email,
        password: formData.password,
        full_name: formData.full_name,
        workspace_name: formData.workspace_name
      })
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl font-bold">Create Account</CardTitle>
          <CardDescription>
            Sign up to start monitoring your agents
          </CardDescription>
        </CardHeader>
        <CardContent>
          {error && (
            <Alert variant="destructive" className="mb-4">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="full_name">Full Name</Label>
              <Input
                id="full_name"
                type="text"
                placeholder="John Doe"
                value={formData.full_name}
                onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                required
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                required
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="workspace_name">Workspace Name</Label>
              <Input
                id="workspace_name"
                type="text"
                placeholder="My Company"
                value={formData.workspace_name}
                onChange={(e) => setFormData({...formData, workspace_name: e.target.value})}
                required
                disabled={loading}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                value={formData.password}
                onChange={(e) => setFormData({...formData, password: e.target.value})}
                required
                disabled={loading}
                minLength={8}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="confirmPassword">Confirm Password</Label>
              <Input
                id="confirmPassword"
                type="password"
                value={formData.confirmPassword}
                onChange={(e) => setFormData({...formData, confirmPassword: e.target.value})}
                required
                disabled={loading}
                minLength={8}
              />
            </div>

            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? 'Creating account...' : 'Create Account'}
            </Button>
          </form>

          <div className="mt-4 text-center text-sm">
            Already have an account?{' '}
            <Link href="/login" className="text-primary hover:underline">
              Sign in
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
```

---

### 4.4 Dashboard Components

**Component Structure:**

```
frontend/components/
├── dashboard/
│   ├── KPICard.tsx                # Reusable KPI card with trend
│   ├── AlertsFeed.tsx             # Recent alerts list
│   ├── ActivityStream.tsx         # Activity table
│   ├── TimeRangeSelector.tsx      # Time filter dropdown
│   └── ProtectedRoute.tsx         # Auth guard wrapper
└── ui/
    └── (shadcn/ui components)
```

**KPICard Component:**

```typescript
// components/dashboard/KPICard.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'

interface KPICardProps {
  title: string
  value: string
  change: number
  changeLabel: string
  trend?: 'normal' | 'inverse'  // inverse for metrics where lower is better
  loading?: boolean
}

export function KPICard({
  title,
  value,
  change,
  changeLabel,
  trend = 'normal',
  loading = false
}: KPICardProps) {
  // Determine if change is positive based on trend
  const isPositive = trend === 'inverse' ? change < 0 : change > 0
  const isNeutral = change === 0

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <Badge variant={isPositive ? "default" : isNeutral ? "secondary" : "destructive"}>
          {isPositive ? (
            <TrendingUp className="h-3 w-3" />
          ) : isNeutral ? (
            <Minus className="h-3 w-3" />
          ) : (
            <TrendingDown className="h-3 w-3" />
          )}
        </Badge>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="animate-pulse">
            <div className="h-8 bg-muted rounded w-24 mb-2"></div>
            <div className="h-4 bg-muted rounded w-32"></div>
          </div>
        ) : (
          <>
            <div className="text-3xl font-bold">{value}</div>
            <p className="text-xs text-muted-foreground mt-1">
              <span className={
                isPositive ? 'text-green-600' :
                isNeutral ? 'text-gray-500' :
                'text-red-600'
              }>
                {change > 0 ? '+' : ''}{change.toFixed(1)}%
              </span>
              {' '}{changeLabel}
            </p>
          </>
        )}
      </CardContent>
    </Card>
  )
}
```

**AlertsFeed Component:**

```typescript
// components/dashboard/AlertsFeed.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Badge } from '@/components/ui/badge'
import { AlertCircle, AlertTriangle, Info } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { formatDistanceToNow } from 'date-fns'

interface AlertItem {
  id: string
  title: string
  description: string
  severity: 'info' | 'warning' | 'critical'
  metric_value?: number
  created_at: string
}

export function AlertsFeed() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['alerts', 'recent'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/alerts/recent?limit=10')
      return response.data.items as AlertItem[]
    },
    refetchInterval: 60000, // Refetch every minute
  })

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical':
        return <AlertCircle className="h-4 w-4" />
      case 'warning':
        return <AlertTriangle className="h-4 w-4" />
      default:
        return <Info className="h-4 w-4" />
    }
  }

  const getSeverityVariant = (severity: string): "default" | "destructive" => {
    return severity === 'critical' ? 'destructive' : 'default'
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle>Recent Alerts</CardTitle>
          <Badge variant="outline">{data?.length || 0} active</Badge>
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-2">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="h-20 bg-muted rounded"></div>
              </div>
            ))}
          </div>
        ) : error ? (
          <Alert variant="destructive">
            <AlertDescription>Failed to load alerts</AlertDescription>
          </Alert>
        ) : data && data.length > 0 ? (
          <ScrollArea className="h-[400px] pr-4">
            <div className="space-y-3">
              {data.map((alert) => (
                <Alert
                  key={alert.id}
                  variant={getSeverityVariant(alert.severity)}
                  className="relative"
                >
                  <div className="flex items-start gap-3">
                    {getSeverityIcon(alert.severity)}
                    <div className="flex-1 space-y-1">
                      <AlertTitle className="text-sm font-medium">
                        {alert.title}
                      </AlertTitle>
                      <AlertDescription className="text-xs">
                        {alert.description}
                      </AlertDescription>
                      <div className="flex items-center gap-2 mt-2">
                        <Badge variant="outline" className="text-xs">
                          {alert.severity}
                        </Badge>
                        <span className="text-xs text-muted-foreground">
                          {formatDistanceToNow(new Date(alert.created_at), { addSuffix: true })}
                        </span>
                      </div>
                    </div>
                  </div>
                </Alert>
              ))}
            </div>
          </ScrollArea>
        ) : (
          <p className="text-sm text-muted-foreground text-center py-8">
            No alerts at this time
          </p>
        )}
      </CardContent>
    </Card>
  )
}
```

**ActivityStream Component:**

```typescript
// components/dashboard/ActivityStream.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import apiClient from '@/lib/api-client'
import { formatDistanceToNow } from 'date-fns'

interface Activity {
  trace_id: string
  agent_id: string
  action: string
  status: 'success' | 'error' | 'timeout'
  timestamp: string
  metadata: {
    latency_ms?: number
    model?: string
    cost_usd?: number
  }
}

export function ActivityStream() {
  const { data, isLoading } = useQuery({
    queryKey: ['activity', 'stream'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/activity/stream?limit=50')
      return response.data.items as Activity[]
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  })

  const getStatusVariant = (status: string): "default" | "destructive" | "secondary" => {
    switch (status) {
      case 'success':
        return 'default'
      case 'error':
        return 'destructive'
      default:
        return 'secondary'
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Activity</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-2">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="h-12 bg-muted rounded"></div>
              </div>
            ))}
          </div>
        ) : (
          <div className="border rounded-lg">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[180px]">Time</TableHead>
                  <TableHead>Agent</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead>Model</TableHead>
                  <TableHead className="text-right">Latency</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data && data.length > 0 ? (
                  data.map((activity) => (
                    <TableRow key={activity.trace_id}>
                      <TableCell className="text-xs text-muted-foreground">
                        {formatDistanceToNow(new Date(activity.timestamp), {
                          addSuffix: true
                        })}
                      </TableCell>
                      <TableCell className="font-medium text-sm">
                        {activity.agent_id}
                      </TableCell>
                      <TableCell className="text-sm">
                        {activity.action.replace('_', ' ')}
                      </TableCell>
                      <TableCell className="text-sm">
                        {activity.metadata.model || '-'}
                      </TableCell>
                      <TableCell className="text-right text-sm">
                        {activity.metadata.latency_ms || '-'} ms
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(activity.status)}>
                          {activity.status}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center text-muted-foreground py-8">
                      No recent activity
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
```

**TimeRangeSelector Component:**

```typescript
// components/dashboard/TimeRangeSelector.tsx
'use client'

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

interface TimeRangeSelectorProps {
  value: string
  onChange: (value: string) => void
}

export function TimeRangeSelector({ value, onChange }: TimeRangeSelectorProps) {
  return (
    <Select value={value} onValueChange={onChange}>
      <SelectTrigger className="w-[180px]">
        <SelectValue placeholder="Select time range" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="1h">Last Hour</SelectItem>
        <SelectItem value="24h">Last 24 Hours</SelectItem>
        <SelectItem value="7d">Last 7 Days</SelectItem>
        <SelectItem value="30d">Last 30 Days</SelectItem>
      </SelectContent>
    </Select>
  )
}
```

---

### 4.5 Updated Dashboard Page

```typescript
// app/dashboard/page.tsx
'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { KPICard } from '@/components/dashboard/KPICard'
import { AlertsFeed } from '@/components/dashboard/AlertsFeed'
import { ActivityStream } from '@/components/dashboard/ActivityStream'
import { TimeRangeSelector } from '@/components/dashboard/TimeRangeSelector'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/app/contexts/AuthContext'

interface HomeKPIs {
  total_requests: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
  avg_latency_ms: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
  error_rate: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
  total_cost_usd: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
}

export default function DashboardPage() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('24h')

  const { data: kpis, isLoading } = useQuery({
    queryKey: ['home-kpis', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/metrics/home-kpis?range=${timeRange}`)
      return response.data as HomeKPIs
    },
    refetchInterval: 300000, // Refetch every 5 minutes
  })

  return (
    <div className="p-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back, {user?.full_name}
          </p>
        </div>
        <TimeRangeSelector value={timeRange} onChange={setTimeRange} />
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
        <KPICard
          title="Total Requests"
          value={kpis?.total_requests.value.toLocaleString() || '—'}
          change={kpis?.total_requests.change || 0}
          changeLabel={kpis?.total_requests.change_label || ''}
          trend="normal"
          loading={isLoading}
        />
        <KPICard
          title="Avg Latency"
          value={kpis ? `${Math.round(kpis.avg_latency_ms.value)}ms` : '—'}
          change={kpis?.avg_latency_ms.change || 0}
          changeLabel={kpis?.avg_latency_ms.change_label || ''}
          trend="inverse"
          loading={isLoading}
        />
        <KPICard
          title="Error Rate"
          value={kpis ? `${kpis.error_rate.value.toFixed(1)}%` : '—'}
          change={kpis?.error_rate.change || 0}
          changeLabel={kpis?.error_rate.change_label || ''}
          trend="inverse"
          loading={isLoading}
        />
        <KPICard
          title="Total Cost"
          value={kpis ? `$${kpis.total_cost_usd.value.toFixed(2)}` : '—'}
          change={kpis?.total_cost_usd.change || 0}
          changeLabel={kpis?.total_cost_usd.change_label || ''}
          trend="normal"
          loading={isLoading}
        />
      </div>

      {/* Alerts and Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <AlertsFeed />
        <ActivityStream />
      </div>
    </div>
  )
}
```

---

## Communication Patterns

### 5.1 API Request Flow

**Authenticated Request Pattern:**

```
Frontend                Gateway               Query Service         Database
   │                       │                        │                   │
   │  GET /api/v1/...     │                        │                   │
   │  Auth: Bearer token  │                        │                   │
   ├─────────────────────>│                        │                   │
   │                       │  1. Verify JWT        │                   │
   │                       │  2. Extract user_id   │                   │
   │                       │     workspace_id      │                   │
   │                       │                        │                   │
   │                       │  GET /internal/...    │                   │
   │                       │  X-Workspace-ID: XXX  │                   │
   │                       ├───────────────────────>│                   │
   │                       │                        │  1. Check cache  │
   │                       │                        ├──────────────┐   │
   │                       │                        │              │   │
   │                       │                        │<─────────────┘   │
   │                       │                        │  Cache MISS      │
   │                       │                        │                   │
   │                       │                        │  SQL Query        │
   │                       │                        ├──────────────────>│
   │                       │                        │                   │
   │                       │                        │<──────────────────┤
   │                       │                        │  Results          │
   │                       │                        │                   │
   │                       │                        │  2. Cache results │
   │                       │                        ├──────────────┐   │
   │                       │                        │              │   │
   │                       │                        │<─────────────┘   │
   │                       │                        │                   │
   │                       │  JSON Response        │                   │
   │                       │<───────────────────────┤                   │
   │                       │                        │                   │
   │  JSON Response       │                        │                   │
   │<─────────────────────┤                        │                   │
   │                       │                        │                   │
```

### 5.2 Gateway Routing Configuration

**Gateway routes.py (to be added in Phase 1):**

```python
# backend/gateway/app/routes.py
from fastapi import APIRouter, Request, HTTPException, Depends
from fastapi.responses import Response
import httpx
from app.auth.jwt import verify_token
from app.dependencies import get_current_user

router = APIRouter()

# Service URLs (from environment)
QUERY_SERVICE_URL = os.getenv("QUERY_SERVICE_URL", "http://query:8003")
INGESTION_SERVICE_URL = os.getenv("INGESTION_SERVICE_URL", "http://ingestion:8001")

@router.api_route("/api/v1/metrics/{path:path}", methods=["GET"])
@router.api_route("/api/v1/alerts/{path:path}", methods=["GET"])
@router.api_route("/api/v1/activity/{path:path}", methods=["GET"])
@router.api_route("/api/v1/traces/{path:path}", methods=["GET", "POST"])
async def proxy_to_query_service(
    path: str,
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """Proxy requests to Query Service with user context"""
    async with httpx.AsyncClient() as client:
        # Forward request to Query Service
        url = f"{QUERY_SERVICE_URL}/api/v1/{path}"

        # Add workspace_id from JWT to headers
        headers = {
            "X-Workspace-ID": current_user["workspace_id"],
            "X-User-ID": current_user["user_id"]
        }

        # Forward query parameters
        params = dict(request.query_params)

        response = await client.request(
            method=request.method,
            url=url,
            params=params,
            headers=headers,
            timeout=30.0
        )

        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=dict(response.headers)
        )

@router.api_route("/api/v1/traces", methods=["POST"])
@router.api_route("/api/v1/traces/batch", methods=["POST"])
async def proxy_to_ingestion_service(
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    """Proxy trace ingestion to Ingestion Service"""
    async with httpx.AsyncClient() as client:
        url = f"{INGESTION_SERVICE_URL}{request.url.path}"

        # Read request body
        body = await request.body()

        response = await client.request(
            method=request.method,
            url=url,
            content=body,
            headers={"Content-Type": "application/json"},
            timeout=30.0
        )

        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=dict(response.headers)
        )
```

---

## Database Architecture

### 6.1 Database Access Patterns

**Query Service Database Strategy:**

1. **Read-Only Access** - Query Service only reads from databases, never writes
2. **Connection Pooling** - Maintain persistent connection pools to both databases
3. **Prefer Aggregates** - Use TimescaleDB continuous aggregates (traces_hourly, traces_daily) over raw traces table
4. **Index Utilization** - All queries use existing indexes from Phase 0

**Query Performance Optimization:**

```sql
-- Example: Optimized home KPIs query using continuous aggregate
-- This query runs in ~50ms instead of ~2000ms on raw traces table

EXPLAIN ANALYZE
WITH current_period AS (
    SELECT
        SUM(request_count) as total_requests,
        AVG(avg_latency_ms) as avg_latency,
        SUM(error_count)::float / NULLIF(SUM(request_count), 0) * 100 as error_rate,
        SUM(total_cost_usd) as total_cost
    FROM traces_hourly
    WHERE workspace_id = '550e8400-e29b-41d4-a716-446655440000'
      AND hour >= NOW() - INTERVAL '24 hours'
)
SELECT * FROM current_period;

-- Result: Execution Time: 47ms (vs 1800ms on raw traces)
```

### 6.2 Cache Invalidation Strategy

**When to Invalidate Cache:**

1. **New Trace Ingested** - Invalidate workspace KPIs after Processing Service writes
2. **Manual Refresh** - User-triggered refresh button
3. **TTL Expiration** - Automatic expiration after configured TTL

**Cache Invalidation Implementation (Processing Service):**

```python
# backend/processing/app/writer.py (to be added)
async def write_traces_batch(traces: List[dict], redis_client: redis.Redis):
    """Write traces to TimescaleDB and invalidate cache"""
    async with pool.acquire() as conn:
        # Write traces
        await conn.copy_records_to_table(
            'traces',
            records=traces,
            columns=TRACE_COLUMNS
        )

    # Invalidate cache for affected workspaces
    workspace_ids = set(t['workspace_id'] for t in traces)
    for workspace_id in workspace_ids:
        # Delete cache keys
        await redis_client.delete(f"home_kpis:{workspace_id}:*")
        await redis_client.delete(f"activity:stream:{workspace_id}:*")
```

---

## Security Architecture

### 7.1 Authentication & Authorization

**JWT Token Structure:**

```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "workspace_id": "660e8400-e29b-41d4-a716-446655440111",
  "email": "user@example.com",
  "exp": 1698345600,
  "iat": 1698259200
}
```

**Authorization Model:**

- **User-Level Auth** - JWT token identifies user and workspace
- **Workspace Isolation** - All queries filtered by workspace_id from token
- **No Row-Level Auth** - Users can access all data in their workspace
- **Future Enhancement** - Role-based access control (RBAC) in Phase 5

### 7.2 API Security

**Gateway Security Middleware:**

1. **CORS** - Restrict origins to configured frontend URLs
2. **Rate Limiting** - 1000 requests/minute per workspace (Redis-based)
3. **Request Validation** - Pydantic models validate all inputs
4. **SQL Injection Prevention** - Parameterized queries only
5. **XSS Prevention** - Content Security Policy headers

**Query Service Security:**

```python
# app/dependencies.py
from fastapi import Header, HTTPException

async def verify_internal_request(
    x_workspace_id: str = Header(...),
    x_user_id: str = Header(...)
):
    """
    Verify request comes from Gateway with user context.
    Query Service should NOT be exposed publicly.
    """
    if not x_workspace_id or not x_user_id:
        raise HTTPException(
            status_code=403,
            detail="Missing user context headers"
        )

    return {
        "workspace_id": x_workspace_id,
        "user_id": x_user_id
    }
```

### 7.3 Data Security

**Sensitive Data Handling:**

1. **No PII in Logs** - Sanitize logs, never log trace input/output
2. **Encrypted Connections** - TLS for all database connections in production
3. **Secrets Management** - Environment variables, never hardcoded
4. **Password Hashing** - bcrypt with salt (implemented in Gateway)

---

## Deployment Architecture

### 8.1 Docker Compose Configuration

**Updated docker-compose.yml (Phase 2 additions):**

```yaml
# Add to existing docker-compose.yml

  # Query Service (Phase 2)
  query:
    build:
      context: ./backend/query
      dockerfile: Dockerfile
    container_name: agent_obs_query
    environment:
      - TIMESCALE_URL=postgresql://postgres:postgres@timescaledb:5432/agent_observability
      - POSTGRES_URL=postgresql://postgres:postgres@postgres:5432/agent_observability_metadata
      - REDIS_URL=redis://:redis123@redis:6379/0
      - CACHE_TTL_HOME_KPIS=300
      - CACHE_TTL_ALERTS=60
      - CACHE_TTL_ACTIVITY=30
    ports:
      - "8003:8003"
    depends_on:
      timescaledb:
        condition: service_healthy
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - agent_obs_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8003/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  # Frontend (Phase 2 - Updated)
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: agent_obs_frontend
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    ports:
      - "3000:3000"
    depends_on:
      - gateway
    networks:
      - agent_obs_network
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next
```

### 8.2 Environment Variables

**Query Service .env.example:**

```bash
# Database Connections
TIMESCALE_URL=postgresql://postgres:postgres@localhost:5432/agent_observability
POSTGRES_URL=postgresql://postgres:postgres@localhost:5433/agent_observability_metadata
REDIS_URL=redis://:redis123@localhost:6379/0

# Cache TTL (seconds)
CACHE_TTL_HOME_KPIS=300
CACHE_TTL_ALERTS=60
CACHE_TTL_ACTIVITY=30
CACHE_TTL_TRACES_LIST=120
CACHE_TTL_TRACE_DETAIL=600

# Connection Pool Settings
DB_POOL_MIN_SIZE=5
DB_POOL_MAX_SIZE=20

# Service Configuration
SERVICE_PORT=8003
LOG_LEVEL=INFO
```

**Frontend .env.local:**

```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Testing Strategy

### 9.1 Backend Testing

**Test Structure:**

```
backend/query/tests/
├── conftest.py                # Pytest fixtures (DB, Redis, mock data)
├── test_home_kpis.py          # 5 tests
├── test_traces.py             # 7 tests
└── test_cache.py              # 3 tests
```

**Test Coverage Requirements:**

| Module | Target Coverage | Critical Paths |
|--------|----------------|----------------|
| routes/home.py | 95% | KPI calculation, error handling |
| routes/traces.py | 90% | Filtering, pagination |
| cache.py | 100% | Get, set, delete, TTL |
| queries.py | 95% | SQL generation, parameterization |

**Example Test Cases:**

```python
# tests/test_home_kpis.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_home_kpis_24h_range(async_client: AsyncClient, mock_workspace):
    """Test home KPIs endpoint with 24h time range"""
    response = await async_client.get(
        "/api/v1/metrics/home-kpis?range=24h",
        headers={"X-Workspace-ID": mock_workspace.id}
    )

    assert response.status_code == 200
    data = response.json()

    assert "total_requests" in data
    assert "avg_latency_ms" in data
    assert "error_rate" in data
    assert "total_cost_usd" in data

    # Validate structure
    assert "value" in data["total_requests"]
    assert "change" in data["total_requests"]
    assert "trend" in data["total_requests"]

@pytest.mark.asyncio
async def test_home_kpis_invalid_range(async_client: AsyncClient):
    """Test home KPIs endpoint with invalid time range"""
    response = await async_client.get(
        "/api/v1/metrics/home-kpis?range=invalid",
        headers={"X-Workspace-ID": "550e8400-e29b-41d4-a716-446655440000"}
    )

    assert response.status_code == 400
    assert "Invalid time range" in response.json()["detail"]

@pytest.mark.asyncio
async def test_home_kpis_caching(
    async_client: AsyncClient,
    mock_workspace,
    redis_client
):
    """Test that home KPIs are cached correctly"""
    # First request - cache miss
    response1 = await async_client.get(
        "/api/v1/metrics/home-kpis?range=24h",
        headers={"X-Workspace-ID": mock_workspace.id}
    )

    # Check cache was populated
    cache_key = f"home_kpis:{mock_workspace.id}:24h"
    cached_value = await redis_client.get(cache_key)
    assert cached_value is not None

    # Second request - cache hit
    response2 = await async_client.get(
        "/api/v1/metrics/home-kpis?range=24h",
        headers={"X-Workspace-ID": mock_workspace.id}
    )

    assert response1.json() == response2.json()

@pytest.mark.asyncio
async def test_home_kpis_no_data(async_client: AsyncClient, empty_workspace):
    """Test home KPIs with workspace that has no data"""
    response = await async_client.get(
        "/api/v1/metrics/home-kpis?range=24h",
        headers={"X-Workspace-ID": empty_workspace.id}
    )

    assert response.status_code == 200
    data = response.json()

    # Should return zeros
    assert data["total_requests"]["value"] == 0
    assert data["total_requests"]["change"] == 0.0

@pytest.mark.asyncio
async def test_home_kpis_percentage_calculation(
    async_client: AsyncClient,
    mock_workspace_with_data
):
    """Test percentage change calculations are correct"""
    response = await async_client.get(
        "/api/v1/metrics/home-kpis?range=24h",
        headers={"X-Workspace-ID": mock_workspace_with_data.id}
    )

    data = response.json()

    # Verify percentage calculations
    assert isinstance(data["total_requests"]["change"], float)
    assert -100 <= data["total_requests"]["change"] <= 10000
```

**Pytest Fixtures (conftest.py):**

```python
# tests/conftest.py
import pytest
import asyncpg
import redis.asyncio as redis
from httpx import AsyncClient
from app.main import app
from app.database import DatabaseManager
from app.cache import CacheManager

@pytest.fixture
async def db_manager():
    """Database manager fixture"""
    manager = DatabaseManager()
    await manager.connect_timescale(TEST_TIMESCALE_URL)
    await manager.connect_postgres(TEST_POSTGRES_URL)
    yield manager
    await manager.close()

@pytest.fixture
async def redis_client():
    """Redis client fixture"""
    client = redis.from_url(TEST_REDIS_URL, decode_responses=True)
    yield client
    await client.flushdb()  # Clean up after each test
    await client.close()

@pytest.fixture
async def async_client():
    """HTTP client fixture"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.fixture
async def mock_workspace(db_manager):
    """Create a test workspace"""
    async with db_manager.postgres_pool.acquire() as conn:
        workspace_id = await conn.fetchval("""
            INSERT INTO workspaces (name)
            VALUES ('Test Workspace')
            RETURNING id
        """)
        yield {"id": str(workspace_id)}
        # Cleanup
        await conn.execute("DELETE FROM workspaces WHERE id = $1", workspace_id)

@pytest.fixture
async def mock_workspace_with_data(db_manager, mock_workspace):
    """Create workspace with sample traces"""
    async with db_manager.timescale_pool.acquire() as conn:
        # Insert sample traces
        for i in range(100):
            await conn.execute("""
                INSERT INTO traces (
                    trace_id, workspace_id, agent_id, timestamp,
                    latency_ms, status, model, model_provider,
                    tokens_total, cost_usd
                ) VALUES (
                    $1, $2, 'test-agent', NOW() - INTERVAL '1 hour' * $3,
                    $4, 'success', 'gpt-4-turbo', 'openai',
                    $5, $6
                )
            """, f"trace_{i}", mock_workspace["id"], i % 24,
                1000 + (i * 10), 300 + i, 0.005 * i
            )

    yield mock_workspace
```

---

### 9.2 Frontend Testing

**Test Structure:**

```
frontend/__tests__/
├── components/
│   ├── KPICard.test.tsx           # 1 test
│   ├── AlertsFeed.test.tsx        # 2 tests
│   └── ActivityStream.test.tsx    # 2 tests
├── pages/
│   └── dashboard.test.tsx         # 1 test
└── setup.ts                       # Testing library setup
```

**Example Component Tests:**

```typescript
// __tests__/components/KPICard.test.tsx
import { render, screen } from '@testing-library/react'
import { KPICard } from '@/components/dashboard/KPICard'

describe('KPICard', () => {
  it('renders with positive change', () => {
    render(
      <KPICard
        title="Total Requests"
        value="12,345"
        change={12.5}
        changeLabel="vs last period"
        trend="normal"
      />
    )

    expect(screen.getByText('Total Requests')).toBeInTheDocument()
    expect(screen.getByText('12,345')).toBeInTheDocument()
    expect(screen.getByText('+12.5%')).toBeInTheDocument()
    expect(screen.getByText('vs last period')).toBeInTheDocument()
  })

  it('shows inverse trend for latency', () => {
    render(
      <KPICard
        title="Avg Latency"
        value="1234ms"
        change={-5.2}
        changeLabel="vs last period"
        trend="inverse"
      />
    )

    // Negative change is good for latency (inverse trend)
    const changeElement = screen.getByText('-5.2%')
    expect(changeElement).toHaveClass('text-green-600')
  })
})
```

**Integration Test Example:**

```typescript
// __tests__/pages/dashboard.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import DashboardPage from '@/app/dashboard/page'
import { AuthContext } from '@/app/contexts/AuthContext'

const mockUser = {
  id: '550e8400-e29b-41d4-a716-446655440000',
  email: 'test@example.com',
  full_name: 'Test User',
  workspace_id: '660e8400-e29b-41d4-a716-446655440111'
}

describe('Dashboard Page', () => {
  it('renders KPI cards with real data', async () => {
    const queryClient = new QueryClient()

    render(
      <AuthContext.Provider value={{ user: mockUser, loading: false }}>
        <QueryClientProvider client={queryClient}>
          <DashboardPage />
        </QueryClientProvider>
      </AuthContext.Provider>
    )

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Total Requests')).toBeInTheDocument()
      expect(screen.getByText('Avg Latency')).toBeInTheDocument()
      expect(screen.getByText('Error Rate')).toBeInTheDocument()
      expect(screen.getByText('Total Cost')).toBeInTheDocument()
    })
  })
})
```

---

### 9.3 Integration Testing

**End-to-End Test Flow:**

```
1. User Registration → JWT Token → Dashboard Load → KPIs Display
2. Login → Token Refresh → Data Query → Cache Hit
3. Trace Ingestion → Cache Invalidation → Dashboard Update
```

**Integration Test (backend/tests/integration/):**

```python
# backend/tests/integration/test_phase2_e2e.py
import pytest
from httpx import AsyncClient

@pytest.mark.integration
@pytest.mark.asyncio
async def test_full_dashboard_flow():
    """
    Test complete flow:
    1. Register user
    2. Login
    3. Query home KPIs
    4. Verify data
    """
    async with AsyncClient(base_url="http://localhost:8000") as client:
        # 1. Register
        register_response = await client.post("/api/v1/auth/register", json={
            "email": "test@example.com",
            "password": "password123",
            "full_name": "Test User",
            "workspace_name": "Test Workspace"
        })
        assert register_response.status_code == 201

        # 2. Login
        login_response = await client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "password123"
        })
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]

        # 3. Query KPIs
        kpi_response = await client.get(
            "/api/v1/metrics/home-kpis?range=24h",
            headers={"Authorization": f"Bearer {token}"}
        )
        assert kpi_response.status_code == 200

        # 4. Verify structure
        data = kpi_response.json()
        assert "total_requests" in data
        assert "value" in data["total_requests"]
```

---

## Implementation Roadmap

### 10.1 Week 1: Query Service Backend

**Day 1-2: Core Infrastructure**
- [ ] Set up Query Service directory structure
- [ ] Configure database connection pooling
- [ ] Implement Redis cache manager
- [ ] Write configuration and environment handling
- [ ] Create health check endpoint

**Day 3-4: Home Dashboard APIs**
- [ ] Implement home KPIs endpoint with caching
- [ ] Implement alerts endpoint
- [ ] Implement activity stream endpoint
- [ ] Write SQL query optimizations
- [ ] Add error handling

**Day 5: Testing**
- [ ] Write 15 unit tests (home_kpis, traces, cache)
- [ ] Test cache TTL and invalidation
- [ ] Performance testing (< 200ms target)

---

### 10.2 Week 2: Frontend Dashboard

**Day 1: Authentication**
- [ ] Create AuthContext and provider
- [ ] Build Login page with validation
- [ ] Build Register page with validation
- [ ] Implement token persistence
- [ ] Add protected route wrapper

**Day 2-3: Dashboard Components**
- [ ] Build KPICard component with loading states
- [ ] Build AlertsFeed with ScrollArea
- [ ] Build ActivityStream table
- [ ] Build TimeRangeSelector
- [ ] Add React Query integration

**Day 4: Dashboard Page**
- [ ] Update dashboard page with real data
- [ ] Connect all components
- [ ] Add loading and error states
- [ ] Implement time range filtering

**Day 5: Frontend Testing**
- [ ] Write 6 component tests
- [ ] Test authentication flow
- [ ] Test dashboard data loading

---

### 10.3 Week 3: Integration & Polish

**Day 1-2: Docker Integration**
- [ ] Create Query Service Dockerfile
- [ ] Update docker-compose.yml
- [ ] Add frontend Dockerfile
- [ ] Test full stack startup

**Day 2-3: Gateway Integration**
- [ ] Add routing to Query Service in Gateway
- [ ] Test authentication flow end-to-end
- [ ] Verify workspace isolation
- [ ] Load test with multiple concurrent users

**Day 4: Integration Testing**
- [ ] Write 3 integration tests (E2E flows)
- [ ] Test cache invalidation after ingestion
- [ ] Verify all services communicate correctly

**Day 5: Documentation & Deployment**
- [ ] Update API documentation
- [ ] Write deployment guide
- [ ] Create runbook for common issues
- [ ] Final acceptance testing

---

## Architecture Decision Records

### ADR-001: Use Redis for Caching Instead of In-Memory

**Context:** Query Service needs caching to achieve < 200ms response times.

**Decision:** Use Redis with 5-minute TTL instead of in-memory caching.

**Rationale:**
- Shared cache across multiple Query Service instances (future horizontal scaling)
- Persistent cache survives service restarts
- TTL management built-in
- Already in infrastructure stack

**Consequences:**
- Additional network hop to Redis (~1-2ms overhead)
- Cache hit rate critical for performance
- Need cache invalidation strategy

**Alternatives Considered:**
- In-memory cache: Simpler but doesn't scale horizontally
- No caching: Too slow (2000ms vs 200ms target)

---

### ADR-002: Use TimescaleDB Continuous Aggregates for KPIs

**Context:** Home KPIs need to query large time-series data efficiently.

**Decision:** Query from continuous aggregates (traces_hourly, traces_daily) instead of raw traces table.

**Rationale:**
- 40x performance improvement (50ms vs 2000ms)
- Pre-aggregated data reduces computation
- Automatic refresh via TimescaleDB policies
- Existing infrastructure from Phase 0

**Consequences:**
- Data has up to 1-hour lag (acceptable for dashboard)
- More complex query patterns
- Requires understanding of continuous aggregates

**Alternatives Considered:**
- Query raw traces: Too slow for production
- Application-level aggregation: Duplicate work, harder to maintain

---

### ADR-003: Separate Query Service from Gateway

**Context:** Need to serve dashboard queries efficiently.

**Decision:** Create dedicated Query Service instead of adding queries to Gateway.

**Rationale:**
- Separation of concerns (auth vs queries)
- Independent scaling (query workload different from auth)
- Clearer service boundaries
- Easier to optimize database connections

**Consequences:**
- One more service to deploy and maintain
- Gateway must proxy requests
- Additional network hop

**Alternatives Considered:**
- Add queries to Gateway: Simpler deployment but violates single responsibility
- Frontend queries database directly: Security risk, no caching layer

---

### ADR-004: Use React Query for Server State Management

**Context:** Dashboard needs to fetch and cache API data efficiently.

**Decision:** Use TanStack Query (React Query) for all API calls.

**Rationale:**
- Built-in caching and refetching
- Loading and error states handled automatically
- Optimistic updates support
- Industry standard for server state

**Consequences:**
- Learning curve for developers unfamiliar with React Query
- Additional dependency
- Cache invalidation must be coordinated with backend

**Alternatives Considered:**
- Redux: Too heavy for pure API calls
- SWR: Similar but React Query has better TypeScript support
- Plain fetch: Too much boilerplate for caching

---

### ADR-005: JWT in localStorage Instead of Cookies

**Context:** Need to store authentication token in browser.

**Decision:** Store JWT in localStorage, add to requests via Axios interceptor.

**Rationale:**
- Simpler CORS handling (no need for credentials)
- Easier to access in React components
- Works well with Axios interceptors
- Standard pattern for SPAs

**Consequences:**
- Vulnerable to XSS attacks (mitigated by CSP headers)
- Must manually add to every request
- Token visible in browser dev tools

**Alternatives Considered:**
- HttpOnly cookies: More secure but complex CORS
- SessionStorage: Lost on tab close
- In-memory only: Lost on page refresh

---

## Appendix A: API Reference Summary

### Query Service Endpoints

| Method | Endpoint | Description | Cache TTL |
|--------|----------|-------------|-----------|
| GET | /api/v1/metrics/home-kpis | Dashboard KPIs | 5 min |
| GET | /api/v1/alerts/recent | Recent alerts | 1 min |
| GET | /api/v1/activity/stream | Activity feed | 30 sec |
| GET | /api/v1/traces | List traces | 2 min |
| GET | /api/v1/traces/{trace_id} | Trace details | 10 min |
| GET | /health | Health check | None |

---

## Appendix B: Performance Benchmarks

### Target Metrics (Phase 2)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Home KPI Response Time (P95) | < 200ms | Apache Bench, 1000 requests |
| Cache Hit Rate | > 80% | Redis INFO stats |
| Dashboard First Load | < 2s | Chrome DevTools |
| Concurrent Users Supported | 100+ | Load testing with k6 |
| Database Connection Pool Usage | < 50% | pg_stat_activity |

### Actual Performance (To be measured after implementation)

| Metric | Actual | Pass/Fail |
|--------|--------|-----------|
| Home KPI Response Time (P95) | TBD | - |
| Cache Hit Rate | TBD | - |
| Dashboard First Load | TBD | - |
| Concurrent Users | TBD | - |

---

## Appendix C: File Checklist

### Backend Files to Create

- [ ] backend/query/app/main.py
- [ ] backend/query/app/config.py
- [ ] backend/query/app/database.py
- [ ] backend/query/app/cache.py
- [ ] backend/query/app/queries.py
- [ ] backend/query/app/models.py (DONE)
- [ ] backend/query/app/routes/__init__.py
- [ ] backend/query/app/routes/home.py
- [ ] backend/query/app/routes/traces.py
- [ ] backend/query/app/routes/metrics.py
- [ ] backend/query/app/utils/time_ranges.py
- [ ] backend/query/app/utils/formatters.py
- [ ] backend/query/tests/conftest.py
- [ ] backend/query/tests/test_home_kpis.py
- [ ] backend/query/tests/test_traces.py
- [ ] backend/query/tests/test_cache.py
- [ ] backend/query/Dockerfile
- [ ] backend/query/requirements.txt
- [ ] backend/query/.env.example

### Frontend Files to Create

- [ ] frontend/app/contexts/AuthContext.tsx
- [ ] frontend/app/login/page.tsx
- [ ] frontend/app/register/page.tsx
- [ ] frontend/app/dashboard/page.tsx (UPDATE)
- [ ] frontend/components/dashboard/KPICard.tsx
- [ ] frontend/components/dashboard/AlertsFeed.tsx
- [ ] frontend/components/dashboard/ActivityStream.tsx
- [ ] frontend/components/dashboard/TimeRangeSelector.tsx
- [ ] frontend/components/dashboard/ProtectedRoute.tsx
- [ ] frontend/__tests__/components/KPICard.test.tsx
- [ ] frontend/__tests__/components/AlertsFeed.test.tsx
- [ ] frontend/__tests__/components/ActivityStream.test.tsx
- [ ] frontend/__tests__/pages/dashboard.test.tsx
- [ ] frontend/lib/api-client.ts (UPDATE)

### Configuration Files to Update

- [ ] docker-compose.yml (Add Query Service, Frontend)
- [ ] backend/gateway/app/routes.py (Add proxying)
- [ ] frontend/package.json (Add testing dependencies)

---

## Summary

This architecture document provides a comprehensive blueprint for Phase 2 implementation. The design prioritizes:

1. **Performance** - Sub-200ms query times through aggressive caching and query optimization
2. **Security** - JWT authentication with workspace isolation
3. **Scalability** - Stateless services ready for horizontal scaling
4. **Maintainability** - Clear separation of concerns, well-documented code
5. **Testability** - 100% coverage of critical paths

Follow this document during implementation to ensure all architectural decisions are properly executed. Refer to specific sections as needed for implementation details.

**Next Steps:**
1. Review this document with team
2. Set up Query Service development environment
3. Begin Week 1 implementation (Core Infrastructure)
4. Daily standups to track progress against roadmap
5. Weekly architecture reviews to address any blockers

---

**Document Owner:** System Architect
**Last Updated:** October 22, 2025
**Status:** Ready for Implementation
