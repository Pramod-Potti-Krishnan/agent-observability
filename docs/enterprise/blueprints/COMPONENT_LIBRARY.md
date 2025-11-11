# Frontend Component Library Contracts

**Purpose**: Standardized component interfaces for consistent UI across all tabs
**Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Blueprint for Enterprise Release

---

## Table of Contents

1. [KPICard Component](#kpicard-component)
2. [FilterBar Component](#filterbar-component)
3. [DrilldownModal Component](#drilldownmodal-component)
4. [Chart Wrapper Patterns](#chart-wrapper-patterns)
5. [Loading & Error States](#loading--error-states)
6. [Common Utilities](#common-utilities)

---

## KPICard Component

**File**: `frontend/components/dashboard/KPICard.tsx`

### Props Interface

```typescript
interface KPICardProps {
  // Required
  title: string
  value: string | number

  // Change indication
  change: number  // Percentage change
  changeLabel: string  // e.g., "vs yesterday", "vs last month"

  // Optional enhancements
  trend?: 'normal' | 'inverse'  // 'inverse' means decrease is good (e.g., error rate)
  sparklineData?: Array<{
    timestamp: string
    value: number
  }>
  departmentBreakdown?: Array<{
    department: string
    value: number
    percentage: number
  }>
  onClick?: () => void
  icon?: React.ReactNode
  loading?: boolean
}
```

### Behavior Specification

**Visual Indicators**:
- Green up arrow (↑) for positive change when `trend='normal'`
- Red down arrow (↓) for negative change when `trend='normal'`
- **Inverse** when `trend='inverse'`:
  - Red up arrow for increase (bad for errors)
  - Green down arrow for decrease (good for errors)

**Interactions**:
- **Hover**: Show department breakdown if provided
- **Click**: Navigate to detail view if `onClick` provided
- **Loading**: Show skeleton with shimmer animation

**Layout**:
```
┌─────────────────────────────────┐
│ Title                    Badge  │
│                                 │
│ Value (large)                   │
│ ±X% (change label)             │
│                                 │
│ [Sparkline if provided]        │
└─────────────────────────────────┘
```

### Implementation Example

```typescript
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown } from 'lucide-react'
import { Sparklines, SparklinesLine } from 'react-sparklines'

export function KPICard({
  title,
  value,
  change,
  changeLabel,
  trend = 'normal',
  sparklineData,
  departmentBreakdown,
  onClick,
  icon,
  loading
}: KPICardProps) {
  const isPositive = trend === 'inverse' ? change < 0 : change > 0

  if (loading) {
    return <KPICardSkeleton />
  }

  return (
    <Card
      className="hover:shadow-lg transition-shadow cursor-pointer relative group"
      onClick={onClick}
    >
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {icon && <span className="mr-2">{icon}</span>}
          {title}
        </CardTitle>
        <Badge variant={isPositive ? "default" : "secondary"}>
          {isPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
        </Badge>
      </CardHeader>

      <CardContent>
        <div className="text-3xl font-bold">{value}</div>
        <p className="text-xs text-muted-foreground mt-1">
          <span className={isPositive ? 'text-green-600' : 'text-red-600'}>
            {change > 0 ? '+' : ''}{change}%
          </span>
          {' '}{changeLabel}
        </p>

        {/* Sparkline */}
        {sparklineData && sparklineData.length > 0 && (
          <div className="mt-4 h-12">
            <Sparklines data={sparklineData.map(d => d.value)} height={40}>
              <SparklinesLine color={isPositive ? "#10b981" : "#ef4444"} />
            </Sparklines>
          </div>
        )}

        {/* Department Breakdown Tooltip */}
        {departmentBreakdown && (
          <div className="absolute inset-0 bg-card/95 p-4 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg z-10">
            <h4 className="text-sm font-semibold mb-2">Breakdown by Department</h4>
            <div className="space-y-1 max-h-48 overflow-y-auto">
              {departmentBreakdown.map(dept => (
                <div key={dept.department} className="flex justify-between text-xs">
                  <span>{dept.department}</span>
                  <span className="font-mono">{dept.value} ({dept.percentage}%)</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

function KPICardSkeleton() {
  return (
    <Card>
      <CardHeader>
        <div className="h-4 w-32 bg-muted animate-pulse rounded" />
      </CardHeader>
      <CardContent>
        <div className="h-8 w-24 bg-muted animate-pulse rounded mb-2" />
        <div className="h-3 w-20 bg-muted animate-pulse rounded" />
      </CardContent>
    </Card>
  )
}
```

---

## FilterBar Component

**File**: `frontend/components/shared/FilterBar.tsx`

### Props Interface

```typescript
interface FilterConfig {
  timeRange: string  // '1h' | '24h' | '7d' | '30d' | '90d' | 'custom'
  department?: string
  environment?: string
  version?: string
  agentStatus?: string
}

interface FilterBarProps {
  onChange?: (filters: FilterConfig) => void
  persistToUrl?: boolean  // Default: true
  persistToLocalStorage?: boolean  // Default: true
  className?: string
}
```

### State Management

**Three-Way Sync**:
1. **React Context**: Global state accessible to all components
2. **URL Query Params**: Shareable links
3. **localStorage**: User preferences

```typescript
import { useSearchParams } from 'next/navigation'
import { useFilterContext } from '@/lib/filter-context'

export function FilterBar({
  onChange,
  persistToUrl = true,
  persistToLocalStorage = true,
  className
}: FilterBarProps) {
  const [searchParams, setSearchParams] = useSearchParams()
  const { filters, setFilters } = useFilterContext()

  // Sync with URL on mount
  useEffect(() => {
    if (persistToUrl) {
      const urlFilters: FilterConfig = {
        timeRange: searchParams.get('range') || '24h',
        department: searchParams.get('dept') || undefined,
        environment: searchParams.get('env') || undefined,
        version: searchParams.get('version') || undefined
      }
      setFilters(urlFilters)
    }
  }, [])

  // Restore from localStorage on mount
  useEffect(() => {
    if (persistToLocalStorage && !persistToUrl) {
      const saved = localStorage.getItem('lastFilters')
      if (saved) {
        setFilters(JSON.parse(saved))
      }
    }
  }, [])

  const handleFilterChange = (key: keyof FilterConfig, value: string) => {
    const newFilters = { ...filters, [key]: value === '' ? undefined : value }
    setFilters(newFilters)

    // Persist to URL
    if (persistToUrl) {
      const params = new URLSearchParams()
      params.set('range', newFilters.timeRange)
      if (newFilters.department) params.set('dept', newFilters.department)
      if (newFilters.environment) params.set('env', newFilters.environment)
      if (newFilters.version) params.set('version', newFilters.version)
      setSearchParams(params)
    }

    // Persist to localStorage
    if (persistToLocalStorage) {
      localStorage.setItem('lastFilters', JSON.stringify(newFilters))
    }

    // Callback
    onChange?.(newFilters)
  }

  return (
    <div className={`flex gap-4 mb-6 p-4 bg-card rounded-lg ${className}`}>
      {/* Time Range */}
      <Select
        value={filters.timeRange}
        onValueChange={(v) => handleFilterChange('timeRange', v)}
      >
        <SelectTrigger className="w-[180px]">
          <SelectValue placeholder="Time Range" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="1h">Last Hour</SelectItem>
          <SelectItem value="24h">Last 24 Hours</SelectItem>
          <SelectItem value="7d">Last 7 Days</SelectItem>
          <SelectItem value="30d">Last 30 Days</SelectItem>
          <SelectItem value="90d">Last 90 Days</SelectItem>
        </SelectContent>
      </Select>

      {/* Department */}
      <Select
        value={filters.department || ''}
        onValueChange={(v) => handleFilterChange('department', v)}
      >
        <SelectTrigger className="w-[200px]">
          <SelectValue placeholder="All Departments" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="">All Departments</SelectItem>
          <SelectItem value="engineering">Engineering</SelectItem>
          <SelectItem value="sales">Sales</SelectItem>
          <SelectItem value="support">Customer Support</SelectItem>
          {/* Dynamic department list from API */}
        </SelectContent>
      </Select>

      {/* Environment */}
      <Select
        value={filters.environment || ''}
        onValueChange={(v) => handleFilterChange('environment', v)}
      >
        <SelectTrigger className="w-[180px]">
          <SelectValue placeholder="All Environments" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="">All Environments</SelectItem>
          <SelectItem value="production">Production</SelectItem>
          <SelectItem value="staging">Staging</SelectItem>
          <SelectItem value="development">Development</SelectItem>
        </SelectContent>
      </Select>

      {/* Version */}
      <Select
        value={filters.version || ''}
        onValueChange={(v) => handleFilterChange('version', v)}
      >
        <SelectTrigger className="w-[150px]">
          <SelectValue placeholder="All Versions" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="">All Versions</SelectItem>
          <SelectItem value="v2.1">v2.1</SelectItem>
          <SelectItem value="v2.0">v2.0</SelectItem>
          <SelectItem value="v1.9">v1.9</SelectItem>
        </SelectContent>
      </Select>

      {/* Reset Button */}
      <Button
        variant="outline"
        size="sm"
        onClick={() => handleFilterChange('timeRange', '24h')}
      >
        Reset
      </Button>
    </div>
  )
}
```

### Filter Context Provider

**File**: `frontend/lib/filter-context.tsx`

```typescript
'use client'
import { createContext, useContext, useState, ReactNode } from 'react'

interface FilterConfig {
  timeRange: string
  department?: string
  environment?: string
  version?: string
}

interface FilterContextType {
  filters: FilterConfig
  setFilters: (filters: FilterConfig) => void
}

const FilterContext = createContext<FilterContextType | undefined>(undefined)

export function FilterProvider({ children }: { children: ReactNode }) {
  const [filters, setFilters] = useState<FilterConfig>({
    timeRange: '24h'
  })

  return (
    <FilterContext.Provider value={{ filters, setFilters }}>
      {children}
    </FilterContext.Provider>
  )
}

export function useFilterContext() {
  const context = useContext(FilterContext)
  if (!context) {
    throw new Error('useFilterContext must be used within FilterProvider')
  }
  return context
}
```

---

## DrilldownModal Component

**File**: `frontend/components/shared/DrilldownModal.tsx`

### Purpose

Unified trace viewer with full execution context. Used across all tabs for detailed trace inspection.

### Props Interface

```typescript
interface DrilldownModalProps {
  traceId: string
  open: boolean
  onClose: () => void
}
```

### Sections

1. **Request Metadata**
   - Trace ID, Agent ID, Timestamp
   - User, Department, Environment, Version
   - Status, Duration, Cost

2. **Timeline**
   - Visual timeline of execution steps
   - Timestamps for each step
   - Duration bars

3. **Input/Output**
   - User input
   - Agent output
   - Token counts

4. **Step Details**
   - Step-by-step execution (if available)
   - Tool calls, function invocations
   - Intermediate results

5. **Cost Breakdown**
   - Tokens by step
   - Cost by model/provider
   - Total cost

6. **Quality Scores**
   - Evaluation results (if available)
   - Rubric scores
   - Feedback

### Implementation Example

```typescript
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { useQuery } from '@tanstack/react-query'
import apiClient from '@/lib/api-client'

export function DrilldownModal({ traceId, open, onClose }: DrilldownModalProps) {
  const { data: trace, isLoading } = useQuery({
    queryKey: ['trace', traceId],
    queryFn: () => apiClient.get(`/api/v1/traces/${traceId}`),
    enabled: open && !!traceId
  })

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Trace Details: {traceId}</DialogTitle>
        </DialogHeader>

        {isLoading ? (
          <LoadingSkeleton />
        ) : (
          <Tabs defaultValue="overview">
            <TabsList>
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="timeline">Timeline</TabsTrigger>
              <TabsTrigger value="input-output">Input/Output</TabsTrigger>
              <TabsTrigger value="cost">Cost</TabsTrigger>
              <TabsTrigger value="quality">Quality</TabsTrigger>
            </TabsList>

            <TabsContent value="overview">
              <TraceOverview trace={trace} />
            </TabsContent>

            <TabsContent value="timeline">
              <TraceTimeline trace={trace} />
            </TabsContent>

            <TabsContent value="input-output">
              <TraceInputOutput trace={trace} />
            </TabsContent>

            <TabsContent value="cost">
              <TraceCostBreakdown trace={trace} />
            </TabsContent>

            <TabsContent value="quality">
              <TraceQuality trace={trace} />
            </TabsContent>
          </Tabs>
        )}
      </DialogContent>
    </Dialog>
  )
}
```

---

## Chart Wrapper Patterns

### Recharts for Standard Charts

**Use Cases**: Line, Bar, Area, Pie charts

```typescript
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts'

export function StandardLineChart({ data, xKey, yKey, title }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey={xKey} />
            <YAxis />
            <Tooltip />
            <Legend />
            <Line type="monotone" dataKey={yKey} stroke="#8884d8" />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
```

### D3 for Custom Visualizations

**Use Cases**: Heatmaps, Sankey diagrams, Force graphs, Custom networks

```typescript
import { useEffect, useRef } from 'react'
import * as d3 from 'd3'

export function D3Heatmap({ data, width = 800, height = 400 }) {
  const svgRef = useRef<SVGSVGElement>(null)

  useEffect(() => {
    if (!data || !svgRef.current) return

    const svg = d3.select(svgRef.current)
    svg.selectAll('*').remove() // Clear previous render

    // D3 visualization code
    const colorScale = d3.scaleSequential(d3.interpolateRdYlGn).domain([0, 100])

    // ... D3 rendering logic

  }, [data])

  return (
    <Card>
      <CardHeader>
        <CardTitle>Heatmap</CardTitle>
      </CardHeader>
      <CardContent>
        <svg ref={svgRef} width={width} height={height} />
      </CardContent>
    </Card>
  )
}
```

### Consistent Color Palette

```typescript
// theme-colors.ts
export const chartColors = {
  primary: '#3b82f6',
  success: '#10b981',
  warning: '#f59e0b',
  danger: '#ef4444',
  info: '#06b6d4',
  neutral: '#6b7280'
}

export const departmentColors = {
  engineering: '#3b82f6',
  sales: '#10b981',
  support: '#f59e0b',
  marketing: '#ec4899',
  finance: '#8b5cf6',
  hr: '#06b6d4',
  operations: '#f97316',
  product: '#14b8a6',
  data: '#6366f1',
  legal: '#64748b'
}
```

---

## Loading & Error States

### Loading Skeleton Pattern

```typescript
export function DashboardSkeleton() {
  return (
    <div className="space-y-6">
      {/* KPI Cards Skeleton */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[...Array(4)].map((_, i) => (
          <Card key={i}>
            <CardHeader>
              <div className="h-4 w-32 bg-muted animate-pulse rounded" />
            </CardHeader>
            <CardContent>
              <div className="h-8 w-24 bg-muted animate-pulse rounded mb-2" />
              <div className="h-3 w-20 bg-muted animate-pulse rounded" />
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Chart Skeleton */}
      <Card>
        <CardHeader>
          <div className="h-5 w-40 bg-muted animate-pulse rounded" />
        </CardHeader>
        <CardContent>
          <div className="h-64 bg-muted animate-pulse rounded" />
        </CardContent>
      </Card>
    </div>
  )
}
```

### Error Boundary Pattern

```typescript
import { Component, ErrorInfo, ReactNode } from 'react'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error?: Error
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Something went wrong</AlertTitle>
          <AlertDescription>
            {this.state.error?.message || 'An unexpected error occurred'}
          </AlertDescription>
          <Button
            variant="outline"
            size="sm"
            className="mt-2"
            onClick={() => this.setState({ hasError: false })}
          >
            Try Again
          </Button>
        </Alert>
      )
    }

    return this.props.children
  }
}
```

---

## Common Utilities

### Format Numbers

```typescript
export function formatNumber(num: number): string {
  return new Intl.NumberFormat('en-US').format(num)
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(amount)
}

export function formatPercentage(value: number, decimals: number = 1): string {
  return `${value.toFixed(decimals)}%`
}
```

### Format Dates

```typescript
import { format, formatDistanceToNow } from 'date-fns'

export function formatDate(date: string | Date): string {
  return format(new Date(date), 'MMM dd, yyyy HH:mm')
}

export function formatRelativeTime(date: string | Date): string {
  return formatDistanceToNow(new Date(date), { addSuffix: true })
}
```

---

## Summary

This component library provides standardized interfaces for:
- ✅ Consistent KPI card styling and behavior
- ✅ Global filter management with multi-way sync
- ✅ Unified trace drilldown experience
- ✅ Chart rendering patterns (Recharts + D3)
- ✅ Loading and error states
- ✅ Common utilities

All components must follow these contracts to ensure UI consistency across all 11 tabs.

**Cross-References**:
- State management: See `ARCHITECTURE_PATTERNS.md`
- API integration: See `API_CONTRACTS.md`
- Testing: See `TESTING_PATTERNS.md`

---

**Document Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Active Blueprint
