# Frontend Architecture
## AI Agent Observability Platform

**Tech Stack:** React 18 + Next.js 14 + TypeScript + Tailwind CSS
**Last Updated:** October 2025
**Status:** Development Specification

---

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [Project Structure](#project-structure)
3. [Routing Architecture](#routing-architecture)
4. [Component Architecture](#component-architecture)
5. [State Management](#state-management)
6. [Styling System](#styling-system)
7. [Data Fetching](#data-fetching)
8. [Real-time Updates](#real-time-updates)
9. [Authentication](#authentication)
10. [Performance Optimization](#performance-optimization)
11. [Build & Deployment](#build--deployment)

---

## Technology Stack

### Core Framework
- **Next.js 14.x** - React framework with App Router
- **React 18.x** - UI library with Server Components
- **TypeScript 5.x** - Type safety and developer experience

### UI & Styling
- **Tailwind CSS 3.x** - Utility-first CSS framework
- **shadcn/ui** - High-quality React components built on Radix UI
- **Radix UI** - Accessible, unstyled component primitives
- **Lucide React** - Icon library (replacing emoji icons in production)
- **Recharts** - Composable charting library for React

### State Management
- **TanStack Query (React Query) v5** - Server state management, caching, and synchronization
- **Zustand** - Lightweight client state management for global UI state
- **React Context** - For theme, auth, and workspace switching

### Data & API
- **Axios** - HTTP client with interceptors for auth
- **TanStack Query** - API layer with automatic caching, refetching, and optimistic updates
- **Zod** - Runtime type validation for API responses
- **Socket.io Client** - Real-time WebSocket connections for live updates

### Development Tools
- **ESLint** - Code linting with Next.js and TypeScript rules
- **Prettier** - Code formatting
- **Husky** - Git hooks for pre-commit linting
- **TypeScript** - Strict mode enabled

### Testing (Phase 2)
- **Vitest** - Unit testing
- **React Testing Library** - Component testing
- **Playwright** - E2E testing

---

## Project Structure

```
app/
├── (auth)/
│   ├── login/
│   │   └── page.tsx
│   ├── signup/
│   │   └── page.tsx
│   └── layout.tsx                  # Auth layout (no sidebar)
│
├── (dashboard)/
│   ├── layout.tsx                  # Main dashboard layout (with sidebar)
│   ├── page.tsx                    # Home page (🏠)
│   ├── usage/
│   │   └── page.tsx                # Usage page (📊)
│   ├── cost/
│   │   └── page.tsx                # Cost page (💲)
│   ├── performance/
│   │   └── page.tsx                # Performance page (🚀)
│   ├── quality/
│   │   └── page.tsx                # Quality page (✨)
│   ├── safety/
│   │   └── page.tsx                # Safety page (🛡️)
│   ├── impact/
│   │   └── page.tsx                # Impact page (📈)
│   └── settings/
│       └── page.tsx                # Settings page (⚙️)
│
├── api/                            # API routes (if needed for SSR/middleware)
│   ├── auth/
│   │   └── [...nextauth]/
│   │       └── route.ts
│   └── webhooks/
│       └── route.ts
│
├── layout.tsx                      # Root layout
├── globals.css                     # Global styles
├── providers.tsx                   # Context providers wrapper
└── not-found.tsx                   # 404 page

components/
├── layout/
│   ├── Sidebar.tsx                 # Left navigation sidebar
│   ├── Header.tsx                  # Top header with breadcrumbs
│   ├── WorkspaceSwitcher.tsx       # Workspace dropdown
│   └── UserMenu.tsx                # User avatar + menu
│
├── ui/                             # shadcn/ui components
│   ├── button.tsx
│   ├── card.tsx
│   ├── dropdown-menu.tsx
│   ├── input.tsx
│   ├── select.tsx
│   ├── dialog.tsx
│   ├── toast.tsx
│   └── ...
│
├── charts/                         # Recharts wrapper components
│   ├── LineChart.tsx
│   ├── BarChart.tsx
│   ├── AreaChart.tsx
│   ├── PieChart.tsx
│   ├── Heatmap.tsx
│   └── ChartContainer.tsx          # Common chart wrapper
│
├── dashboard/                      # Dashboard-specific components
│   ├── MetricCard.tsx              # KPI card with trend indicator
│   ├── AlertCard.tsx               # Alert/notification card
│   ├── ActivityFeed.tsx            # Activity stream component
│   ├── DataTable.tsx               # Generic data table with sorting/filtering
│   ├── FilterBar.tsx               # Common filter controls
│   └── DateRangePicker.tsx         # Date range selector
│
├── usage/                          # Usage page components
│   ├── UsageMap.tsx                # Geographic user map
│   ├── AdoptionChart.tsx           # Cohort retention heatmap
│   └── InteractionTable.tsx        # Interaction logs table
│
├── cost/                           # Cost page components
│   ├── BudgetOverview.tsx          # Budget progress bar
│   ├── CostBreakdown.tsx           # Cost by agent/model
│   └── ForecastChart.tsx           # Cost forecasting
│
├── performance/                    # Performance page components
│   ├── LatencyChart.tsx            # Percentile latency chart
│   ├── ErrorMonitor.tsx            # Error feed
│   └── UptimeStatus.tsx            # Uptime visualization
│
├── quality/                        # Quality page components
│   ├── QualityDashboard.tsx        # Quality metrics radar chart
│   ├── FeedbackAnalysis.tsx        # Sentiment analysis
│   └── EvaluationHistory.tsx       # Past evaluations list
│
├── safety/                         # Safety page components
│   ├── GuardrailCard.tsx           # Guardrail status card
│   ├── ViolationLog.tsx            # Violation feed
│   └── AuditTrail.tsx              # Audit log timeline
│
├── impact/                         # Impact page components
│   ├── ROIDashboard.tsx            # ROI calculation display
│   ├── GoalTracker.tsx             # Goal progress cards
│   └── ImpactChart.tsx             # Impact by agent
│
└── shared/                         # Shared utilities
    ├── LoadingSpinner.tsx
    ├── ErrorBoundary.tsx
    ├── EmptyState.tsx
    └── SkeletonLoader.tsx

lib/
├── api/
│   ├── client.ts                   # Axios instance with interceptors
│   ├── queries/                    # TanStack Query hooks
│   │   ├── useUsageMetrics.ts
│   │   ├── useCostMetrics.ts
│   │   ├── usePerformanceMetrics.ts
│   │   ├── useQualityMetrics.ts
│   │   ├── useSafetyMetrics.ts
│   │   └── useImpactMetrics.ts
│   └── mutations/                  # Mutation hooks
│       ├── useCreateEvaluation.ts
│       ├── useUpdateGuardrail.ts
│       └── useGenerateInsights.ts
│
├── hooks/                          # Custom React hooks
│   ├── useAuth.ts                  # Authentication hook
│   ├── useWorkspace.ts             # Workspace context hook
│   ├── useRealtime.ts              # WebSocket hook
│   ├── useDebounce.ts              # Debounce hook
│   └── useLocalStorage.ts          # Local storage sync hook
│
├── stores/                         # Zustand stores
│   ├── uiStore.ts                  # UI state (sidebar collapsed, theme)
│   ├── filtersStore.ts             # Global filters (date range, agent)
│   └── alertsStore.ts              # In-app notifications
│
├── utils/
│   ├── formatting.ts               # Number/date formatting utilities
│   ├── calculations.ts             # ROI, percentage calculations
│   ├── validation.ts               # Form validation helpers
│   └── constants.ts                # App constants
│
└── types/
    ├── api.ts                      # API request/response types
    ├── metrics.ts                  # Metrics data types
    ├── agents.ts                   # Agent types
    └── user.ts                     # User/workspace types

public/
├── fonts/
│   └── inter/                      # Self-hosted Inter font
├── images/
│   └── logo.svg
└── favicon.ico

.env.local                          # Environment variables
next.config.js                      # Next.js configuration
tailwind.config.js                  # Tailwind configuration
tsconfig.json                       # TypeScript configuration
package.json                        # Dependencies
```

---

## Routing Architecture

### App Router (Next.js 14)

We use Next.js 14's **App Router** for file-based routing with React Server Components.

#### Route Groups

**`(auth)` group** - Authentication pages without dashboard layout:
```
/login    → app/(auth)/login/page.tsx
/signup   → app/(auth)/signup/page.tsx
```

**`(dashboard)` group** - Main application pages with sidebar layout:
```
/              → app/(dashboard)/page.tsx              # Home
/usage         → app/(dashboard)/usage/page.tsx        # Usage
/cost          → app/(dashboard)/cost/page.tsx         # Cost
/performance   → app/(dashboard)/performance/page.tsx  # Performance
/quality       → app/(dashboard)/quality/page.tsx      # Quality
/safety        → app/(dashboard)/safety/page.tsx       # Safety
/impact        → app/(dashboard)/impact/page.tsx       # Impact
/settings      → app/(dashboard)/settings/page.tsx     # Settings
```

#### Layout Hierarchy

```tsx
// app/layout.tsx - Root layout (applies to all pages)
export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  )
}

// app/(dashboard)/layout.tsx - Dashboard layout (sidebar + header)
export default function DashboardLayout({ children }) {
  return (
    <div className="flex h-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col">
        <Header />
        <main className="flex-1 overflow-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}

// app/(auth)/layout.tsx - Auth layout (centered, no sidebar)
export default function AuthLayout({ children }) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      {children}
    </div>
  )
}
```

#### Protected Routes

Use middleware for authentication:

```tsx
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth-token')

  // Redirect to login if not authenticated
  if (!token && !request.nextUrl.pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Redirect to dashboard if authenticated and on auth pages
  if (token && request.nextUrl.pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}
```

---

## Component Architecture

### Design Principles

1. **Server Components by Default** - Use React Server Components for static content and data fetching
2. **Client Components When Needed** - Use `'use client'` for interactivity, state, or browser APIs
3. **Composition Over Configuration** - Build complex UIs from simple, composable components
4. **Accessibility First** - Use Radix UI primitives for accessible components
5. **Type Safety** - Full TypeScript coverage with strict mode

### Component Patterns

#### 1. Server Components (Default)

```tsx
// app/(dashboard)/usage/page.tsx
import { UsageMetrics } from '@/components/usage/UsageMetrics'

async function getUsageData() {
  const res = await fetch('https://api.yourapp.com/metrics/usage', {
    next: { revalidate: 60 } // Cache for 60 seconds
  })
  return res.json()
}

export default async function UsagePage() {
  const data = await getUsageData()

  return (
    <div>
      <h1>Usage Analytics</h1>
      <UsageMetrics data={data} />
    </div>
  )
}
```

#### 2. Client Components (Interactive)

```tsx
// components/dashboard/MetricCard.tsx
'use client'

import { TrendingUp, TrendingDown } from 'lucide-react'
import { Card } from '@/components/ui/card'

interface MetricCardProps {
  title: string
  value: string | number
  change: number
  changeLabel: string
  onClick?: () => void
}

export function MetricCard({ title, value, change, changeLabel, onClick }: MetricCardProps) {
  const isPositive = change > 0

  return (
    <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer" onClick={onClick}>
      <h3 className="text-sm font-medium text-gray-600">{title}</h3>
      <div className="mt-2 flex items-baseline">
        <p className="text-3xl font-semibold text-gray-900">{value}</p>
      </div>
      <div className="mt-2 flex items-center text-sm">
        {isPositive ? (
          <TrendingUp className="h-4 w-4 text-emerald-500 mr-1" />
        ) : (
          <TrendingDown className="h-4 w-4 text-rose-500 mr-1" />
        )}
        <span className={isPositive ? 'text-emerald-600' : 'text-rose-600'}>
          {Math.abs(change)}%
        </span>
        <span className="text-gray-500 ml-2">{changeLabel}</span>
      </div>
    </Card>
  )
}
```

#### 3. Compound Components

```tsx
// components/dashboard/FilterBar.tsx
'use client'

import { DateRangePicker } from './DateRangePicker'
import { Select } from '@/components/ui/select'
import { useFiltersStore } from '@/lib/stores/filtersStore'

export function FilterBar() {
  const { dateRange, agent, setDateRange, setAgent } = useFiltersStore()

  return (
    <div className="flex gap-4 items-center">
      <DateRangePicker value={dateRange} onChange={setDateRange} />
      <Select value={agent} onChange={setAgent} placeholder="All Agents">
        <option value="all">All Agents</option>
        <option value="support">Customer Support</option>
        <option value="sales">Sales Assistant</option>
      </Select>
    </div>
  )
}
```

---

## State Management

### Three-Tier State Strategy

#### 1. Server State (TanStack Query)

For API data, caching, and synchronization:

```tsx
// lib/api/queries/useUsageMetrics.ts
import { useQuery } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'

export function useUsageMetrics(dateRange: string) {
  return useQuery({
    queryKey: ['usage-metrics', dateRange],
    queryFn: () => apiClient.get(`/metrics/usage?range=${dateRange}`),
    staleTime: 60 * 1000, // 1 minute
    refetchInterval: 60 * 1000, // Auto-refetch every minute
  })
}

// Usage in component
'use client'

function UsageDashboard() {
  const { data, isLoading, error } = useUsageMetrics('30d')

  if (isLoading) return <SkeletonLoader />
  if (error) return <ErrorState error={error} />

  return <UsageCharts data={data} />
}
```

#### 2. Global UI State (Zustand)

For lightweight client-side state:

```tsx
// lib/stores/uiStore.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface UIState {
  sidebarCollapsed: boolean
  theme: 'light' | 'dark'
  toggleSidebar: () => void
  setTheme: (theme: 'light' | 'dark') => void
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      sidebarCollapsed: false,
      theme: 'light',
      toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
      setTheme: (theme) => set({ theme }),
    }),
    {
      name: 'ui-storage', // LocalStorage key
    }
  )
)

// Usage in component
'use client'

function Sidebar() {
  const { sidebarCollapsed, toggleSidebar } = useUIStore()

  return (
    <aside className={sidebarCollapsed ? 'w-16' : 'w-64'}>
      <button onClick={toggleSidebar}>Toggle</button>
    </aside>
  )
}
```

#### 3. Context State (React Context)

For auth and workspace:

```tsx
// lib/contexts/AuthContext.tsx
'use client'

import { createContext, useContext, useState, useEffect } from 'react'

interface User {
  id: string
  email: string
  name: string
}

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check for existing session
    checkAuth()
  }, [])

  const checkAuth = async () => {
    // Verify token and fetch user
    setLoading(false)
  }

  const login = async (email: string, password: string) => {
    // Login logic
  }

  const logout = async () => {
    // Logout logic
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}
```

---

## Styling System

### Tailwind CSS + shadcn/ui

**Configuration:**

```js
// tailwind.config.js
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Primary colors from PRD
        primary: {
          50: '#EEF2FF',
          100: '#E0E7FF',
          200: '#C7D2FE',
          300: '#A5B4FC',
          400: '#818CF8',
          500: '#6366F1',  // Indigo
          600: '#4F46E5',
          700: '#4338CA',
          800: '#3730A3',
          900: '#312E81',
        },
        success: {
          500: '#10B981',  // Emerald
          600: '#059669',
        },
        warning: {
          500: '#F59E0B',  // Amber
          600: '#D97706',
        },
        danger: {
          500: '#EF4444',  // Rose
          600: '#DC2626',
        },
      },
      fontFamily: {
        sans: ['var(--font-inter)', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      borderRadius: {
        lg: '12px',
        md: '8px',
      },
      boxShadow: {
        card: '0 1px 3px rgba(0,0,0,0.1)',
        'card-hover': '0 4px 6px rgba(0,0,0,0.1)',
      },
    },
  },
  plugins: [require('@tailwindcss/forms'), require('tailwindcss-animate')],
}
```

**Global Styles:**

```css
/* app/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --font-inter: 'Inter', system-ui, sans-serif;
}

@layer base {
  * {
    @apply border-gray-200;
  }

  body {
    @apply bg-gray-50 text-gray-900 antialiased;
  }

  h1 {
    @apply text-4xl font-semibold;
  }

  h2 {
    @apply text-2xl font-semibold;
  }

  h3 {
    @apply text-lg font-medium;
  }
}

@layer components {
  .metric-card {
    @apply bg-white rounded-lg shadow-card p-6 transition-shadow hover:shadow-card-hover;
  }

  .btn-primary {
    @apply bg-primary-500 text-white px-6 py-3 rounded-md font-medium hover:bg-primary-600 transition-colors;
  }

  .btn-secondary {
    @apply bg-white text-primary-500 border-2 border-primary-500 px-6 py-3 rounded-md font-medium hover:bg-primary-50 transition-colors;
  }
}
```

---

## Data Fetching

### TanStack Query Setup

```tsx
// app/providers.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1 minute
            retry: 3,
            refetchOnWindowFocus: false,
          },
        },
      })
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

### API Client

```tsx
// lib/api/client.ts
import axios from 'axios'

export const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor (add auth token)
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth-token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Response interceptor (handle errors)
apiClient.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // Redirect to login
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)
```

---

## Real-time Updates

### WebSocket Integration

```tsx
// lib/hooks/useRealtime.ts
'use client'

import { useEffect } from 'use client'
import { io, Socket } from 'socket.io-client'
import { useQueryClient } from '@tanstack/react-query'

export function useRealtime() {
  const queryClient = useQueryClient()

  useEffect(() => {
    const socket: Socket = io(process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000', {
      auth: {
        token: localStorage.getItem('auth-token'),
      },
    })

    // Listen for metric updates
    socket.on('metrics:update', (data) => {
      queryClient.invalidateQueries({ queryKey: ['metrics'] })
    })

    // Listen for alerts
    socket.on('alert:new', (alert) => {
      queryClient.setQueryData(['alerts'], (old: any) => [...old, alert])
    })

    return () => {
      socket.disconnect()
    }
  }, [queryClient])
}

// Usage in layout
'use client'

export default function DashboardLayout({ children }) {
  useRealtime() // Subscribe to real-time updates

  return <>{children}</>
}
```

---

## Authentication

### JWT-based Authentication

```tsx
// lib/api/auth.ts
import { apiClient } from './client'

interface LoginResponse {
  token: string
  user: {
    id: string
    email: string
    name: string
  }
}

export const authAPI = {
  login: async (email: string, password: string): Promise<LoginResponse> => {
    const response = await apiClient.post('/auth/login', { email, password })
    localStorage.setItem('auth-token', response.token)
    return response
  },

  logout: async () => {
    localStorage.removeItem('auth-token')
    await apiClient.post('/auth/logout')
  },

  me: async () => {
    return apiClient.get('/auth/me')
  },
}
```

---

## Performance Optimization

### 1. Code Splitting

```tsx
// Dynamic imports for large components
import dynamic from 'next/dynamic'

const HeavyChart = dynamic(() => import('@/components/charts/HeavyChart'), {
  loading: () => <SkeletonLoader />,
  ssr: false, // Disable SSR for client-only components
})
```

### 2. Image Optimization

```tsx
import Image from 'next/image'

<Image
  src="/logo.svg"
  alt="Logo"
  width={200}
  height={50}
  priority // For above-the-fold images
/>
```

### 3. Font Optimization

```tsx
// app/layout.tsx
import { Inter } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>{children}</body>
    </html>
  )
}
```

### 4. Memoization

```tsx
'use client'

import { useMemo } from 'react'

function ExpensiveComponent({ data }) {
  const processedData = useMemo(() => {
    return data.map(item => /* expensive calculation */)
  }, [data])

  return <Chart data={processedData} />
}
```

---

## Build & Deployment

### Environment Variables

```bash
# .env.local
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_WS_URL=wss://ws.yourdomain.com
NEXT_PUBLIC_GEMINI_API_KEY=your_key_here
```

### Build Configuration

```js
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', // For Docker deployment
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['yourdomain.com'],
  },
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
}

module.exports = nextConfig
```

### Deployment

**Vercel (Recommended):**
```bash
npm run build
vercel --prod
```

**Docker:**
```dockerfile
FROM node:18-alpine AS base

# Install dependencies
FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# Build
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Production
FROM base AS runner
WORKDIR /app
ENV NODE_ENV production
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["node", "server.js"]
```

---

## Summary

This frontend architecture provides:
- **Modern Stack:** Next.js 14 + React 18 + TypeScript
- **Scalable Structure:** Organized by feature with clear separation of concerns
- **Type Safety:** Full TypeScript coverage
- **Performance:** Server Components, code splitting, optimized images
- **Real-time:** WebSocket integration for live updates
- **Developer Experience:** TanStack Query, Zustand, shadcn/ui, Tailwind CSS
- **Production Ready:** Authentication, error handling, loading states

**Next Steps:**
1. Review ui-pages-specification.md for detailed page implementations
2. Review backend-services-architecture.md for API contracts
3. Set up development environment and install dependencies
4. Begin with authentication flow and dashboard layout
