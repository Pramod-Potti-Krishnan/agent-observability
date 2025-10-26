# UI Pages Specification
## AI Agent Observability Platform

**Framework:** React + Next.js 14 + Recharts
**Last Updated:** October 2025
**Status:** Implementation Specification

---

## Table of Contents

1. [Home Page](#1-home-page)
2. [Usage Page](#2-usage-page)
3. [Cost Page](#3-cost-page)
4. [Performance Page](#4-performance-page)
5. [Quality Page](#5-quality-page)
6. [Safety Page](#6-safety-page)
7. [Impact Page](#7-impact-page)
8. [Settings Page](#8-settings-page)
9. [Shared Components](#9-shared-components)

---

## 1. Home Page

**Route:** `/`
**File:** `app/(dashboard)/page.tsx`

### Purpose
High-level command center showing system health, critical alerts, and quick access to common tasks.

### Component Structure

```tsx
// app/(dashboard)/page.tsx
import { KPISection } from '@/components/home/KPISection'
import { AlertsFeed } from '@/components/home/AlertsFeed'
import { ActivityStream } from '@/components/home/ActivityStream'
import { QuickActions } from '@/components/home/QuickActions'

export default async function HomePage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-semibold">Home</h1>
        <div className="flex gap-3">
          <DateRangePicker defaultValue="24h" />
          <Button variant="ghost" size="sm">
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <KPISection />
      <AlertsFeed />
      <ActivityStream />
      <QuickActions />
    </div>
  )
}
```

### Sub-components

#### 1.1 KPI Section

```tsx
// components/home/KPISection.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { MetricCard } from '@/components/dashboard/MetricCard'
import { useRouter } from 'next/navigation'

export function KPISection() {
  const { data, isLoading } = useQuery({
    queryKey: ['home-kpis'],
    queryFn: () => apiClient.get('/metrics/home-kpis'),
  })

  const router = useRouter()

  if (isLoading) return <div className="grid grid-cols-4 gap-6"><SkeletonCard /></div>

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <MetricCard
        title="Total Users"
        value={data.totalUsers.toLocaleString()}
        change={data.totalUsersChange}
        changeLabel="vs last period"
        onClick={() => router.push('/usage')}
      />
      <MetricCard
        title="Total Cost"
        value={`$${data.totalCost.toFixed(2)}`}
        change={data.totalCostChange}
        changeLabel="vs last period"
        onClick={() => router.push('/cost')}
      />
      <MetricCard
        title="Avg Latency"
        value={`${data.avgLatency}s`}
        change={data.avgLatencyChange}
        changeLabel="vs last period"
        trend="inverse" // Lower is better
        onClick={() => router.push('/performance')}
      />
      <MetricCard
        title="Quality Score"
        value={`${data.qualityScore}%`}
        change={data.qualityScoreChange}
        changeLabel="vs last period"
        onClick={() => router.push('/quality')}
      />
    </div>
  )
}
```

**API Contract:**
```typescript
GET /api/metrics/home-kpis?range=24h

Response:
{
  totalUsers: 12439,
  totalUsersChange: 23,
  totalCost: 847.23,
  totalCostChange: 15,
  avgLatency: 1.2,
  avgLatencyChange: -8,
  qualityScore: 92.4,
  qualityScoreChange: 3
}
```

#### 1.2 Alerts Feed

```tsx
// components/home/AlertsFeed.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { AlertCard } from '@/components/dashboard/AlertCard'

export function AlertsFeed() {
  const { data: alerts } = useQuery({
    queryKey: ['alerts'],
    queryFn: () => apiClient.get('/alerts/recent'),
    refetchInterval: 30000, // Refetch every 30s
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold">Live Alerts Feed</h2>
        <div className="flex gap-2">
          <Select defaultValue="all">
            <option value="all">All Severities</option>
            <option value="critical">Critical</option>
            <option value="warning">Warning</option>
          </Select>
          <Button variant="ghost" size="sm">Mark All Read</Button>
        </div>
      </div>

      <div className="space-y-3">
        {alerts?.map((alert) => (
          <AlertCard key={alert.id} alert={alert} />
        ))}
      </div>
    </div>
  )
}

// components/dashboard/AlertCard.tsx
interface AlertCardProps {
  alert: {
    id: string
    severity: 'critical' | 'warning' | 'info'
    title: string
    description: string
    timestamp: string
    actions?: Array<{ label: string; href?: string; onClick?: () => void }>
  }
}

export function AlertCard({ alert }: AlertCardProps) {
  const severityStyles = {
    critical: 'border-l-4 border-rose-500 bg-rose-50',
    warning: 'border-l-4 border-amber-500 bg-amber-50',
    info: 'border-l-4 border-blue-500 bg-blue-50',
  }

  return (
    <div className={`p-4 rounded-lg ${severityStyles[alert.severity]}`}>
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <Badge severity={alert.severity} />
            <span className="text-sm text-gray-500">{formatTimeAgo(alert.timestamp)}</span>
          </div>
          <h3 className="font-semibold mt-1">{alert.title}</h3>
          <p className="text-sm text-gray-700 mt-1">{alert.description}</p>
          {alert.actions && (
            <div className="flex gap-2 mt-3">
              {alert.actions.map((action, idx) => (
                <Button key={idx} variant="outline" size="sm" onClick={action.onClick}>
                  {action.label}
                </Button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
```

**API Contract:**
```typescript
GET /api/alerts/recent?limit=10

Response:
{
  alerts: [
    {
      id: "alert_123",
      severity: "critical",
      title: "Budget Overrun",
      description: "Monthly spend reached 105% of budget",
      timestamp: "2025-10-21T14:32:00Z",
      metadata: {
        currentSpend: 1050,
        budget: 1000
      }
    }
  ]
}
```

#### 1.3 Activity Stream

```tsx
// components/home/ActivityStream.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { Activity } from 'lucide-react'

export function ActivityStream() {
  const { data: activities } = useQuery({
    queryKey: ['activities'],
    queryFn: () => apiClient.get('/activities/recent'),
  })

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h2 className="text-xl font-semibold mb-4">Recent Activity Stream</h2>

      <div className="flex gap-2 mb-4">
        <Button variant="ghost" size="sm">All</Button>
        <Button variant="ghost" size="sm">Evaluations</Button>
        <Button variant="ghost" size="sm">Deployments</Button>
        <Button variant="ghost" size="sm">Config Changes</Button>
      </div>

      <div className="space-y-3">
        {activities?.map((activity) => (
          <div key={activity.id} className="flex items-start gap-3 py-2">
            <div className="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
              <Activity className="h-4 w-4 text-primary-600" />
            </div>
            <div className="flex-1">
              <p className="text-sm">
                <span className="font-medium">{activity.userEmail}</span>{' '}
                {activity.action}
              </p>
              <p className="text-xs text-gray-500">{formatTimeAgo(activity.timestamp)}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
```

---

## 2. Usage Page

**Route:** `/usage`
**File:** `app/(dashboard)/usage/page.tsx`

### Component Structure

```tsx
// app/(dashboard)/usage/page.tsx
import { UsageMetrics } from '@/components/usage/UsageMetrics'
import { UsageMap } from '@/components/usage/UsageMap'
import { TimeSeriesChart } from '@/components/usage/TimeSeriesChart'
import { AgentActivityChart } from '@/components/usage/AgentActivityChart'
import { InteractionTable } from '@/components/usage/InteractionTable'

export default function UsagePage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-semibold">Usage Analytics</h1>
        <div className="flex gap-3">
          <DateRangePicker defaultValue="30d" />
          <Button variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      <Tabs defaultValue="overview">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="adoption">Adoption</TabsTrigger>
          <TabsTrigger value="interactions">Interactions</TabsTrigger>
          <TabsTrigger value="insights">Gemini Insights</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          <UsageMetrics />
          <UsageMap />
          <TimeSeriesChart />
          <AgentActivityChart />
        </TabsContent>

        <TabsContent value="interactions">
          <InteractionTable />
        </TabsContent>
      </Tabs>
    </div>
  )
}
```

### Key Charts

#### 2.1 Time Series Chart (Recharts)

```tsx
// components/usage/TimeSeriesChart.tsx
'use client'

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { useQuery } from '@tanstack/react-query'

export function TimeSeriesChart() {
  const { data } = useQuery({
    queryKey: ['usage-timeseries'],
    queryFn: () => apiClient.get('/metrics/usage/timeseries?range=30d'),
  })

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Requests Over Time</h3>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data?.timeseries || []}>
          <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
          <XAxis
            dataKey="timestamp"
            tickFormatter={(value) => new Date(value).toLocaleDateString()}
            stroke="#6B7280"
          />
          <YAxis stroke="#6B7280" />
          <Tooltip
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #E5E7EB',
              borderRadius: '8px',
            }}
          />
          <Line
            type="monotone"
            dataKey="requests"
            stroke="#6366F1"
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 6 }}
          />
        </LineChart>
      </ResponsiveContainer>
      <div className="mt-4 text-sm text-gray-600">
        <p>Peak: {data?.peak?.toLocaleString()} req/hour at {data?.peakTime}</p>
        <p>Trough: {data?.trough?.toLocaleString()} req/hour at {data?.troughTime}</p>
      </div>
    </div>
  )
}
```

**API Contract:**
```typescript
GET /api/metrics/usage/timeseries?range=30d

Response:
{
  timeseries: [
    { timestamp: "2025-10-01T00:00:00Z", requests: 1234 },
    { timestamp: "2025-10-02T00:00:00Z", requests: 1456 },
    ...
  ],
  peak: 2345,
  peakTime: "2pm EST",
  trough: 234,
  troughTime: "3am EST"
}
```

#### 2.2 Agent Activity Bar Chart

```tsx
// components/usage/AgentActivityChart.tsx
'use client'

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts'

export function AgentActivityChart() {
  const { data } = useQuery({
    queryKey: ['usage-by-agent'],
    queryFn: () => apiClient.get('/metrics/usage/by-agent'),
  })

  const COLORS = ['#6366F1', '#8B5CF6', '#EC4899', '#F59E0B']

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Top Agents by Activity</h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data?.agents || []} layout="vertical">
          <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
          <XAxis type="number" stroke="#6B7280" />
          <YAxis dataKey="name" type="category" width={150} stroke="#6B7280" />
          <Tooltip />
          <Bar dataKey="sessions" radius={[0, 8, 8, 0]}>
            {data?.agents.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
```

---

## 3. Cost Page

**Route:** `/cost`
**File:** `app/(dashboard)/cost/page.tsx`

### Key Components

#### 3.1 Budget Overview

```tsx
// components/cost/BudgetOverview.tsx
'use client'

export function BudgetOverview() {
  const { data } = useQuery({
    queryKey: ['cost-budget'],
    queryFn: () => apiClient.get('/metrics/cost/budget'),
  })

  const percentage = (data.currentSpend / data.budget) * 100

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Budget Overview</h3>

      <div className="space-y-4">
        <div className="flex justify-between items-baseline">
          <span className="text-3xl font-bold">${data.currentSpend.toFixed(2)}</span>
          <span className="text-gray-600">/ ${data.budget.toFixed(2)}</span>
        </div>

        <div className="relative">
          <div className="h-3 bg-gray-200 rounded-full overflow-hidden">
            <div
              className={`h-full transition-all ${
                percentage > 100 ? 'bg-rose-500' : percentage > 80 ? 'bg-amber-500' : 'bg-emerald-500'
              }`}
              style={{ width: `${Math.min(percentage, 100)}%` }}
            />
          </div>
          <div className="absolute -top-1 left-0 w-full flex justify-between text-xs text-gray-500">
            <span>0%</span>
            <span>50%</span>
            <span>100%</span>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 pt-4 border-t">
          <div>
            <p className="text-sm text-gray-600">Remaining</p>
            <p className="text-xl font-semibold">${data.remaining.toFixed(2)}</p>
          </div>
          <div>
            <p className="text-sm text-gray-600">Projected EOM</p>
            <p className="text-xl font-semibold">${data.projectedEOM.toFixed(2)}</p>
            {data.projectedEOM <= data.budget ? (
              <span className="text-xs text-emerald-600">✓ Within budget</span>
            ) : (
              <span className="text-xs text-rose-600">⚠ Over budget</span>
            )}
          </div>
        </div>

        <div className="flex gap-2">
          <Button variant="outline" size="sm">Edit Budget</Button>
          <Button variant="outline" size="sm">Set Alerts</Button>
        </div>
      </div>
    </div>
  )
}
```

#### 3.2 Cost Stacked Area Chart

```tsx
// components/cost/CostTrendChart.tsx
'use client'

import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

export function CostTrendChart() {
  const { data } = useQuery({
    queryKey: ['cost-trend'],
    queryFn: () => apiClient.get('/metrics/cost/trend?range=30d'),
  })

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Cost Trend (Last 30 Days)</h3>
      <ResponsiveContainer width="100%" height={300}>
        <AreaChart data={data?.daily || []}>
          <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
          <XAxis
            dataKey="date"
            tickFormatter={(value) => new Date(value).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
            stroke="#6B7280"
          />
          <YAxis stroke="#6B7280" tickFormatter={(value) => `$${value}`} />
          <Tooltip
            formatter={(value) => `$${value}`}
            contentStyle={{ backgroundColor: '#fff', border: '1px solid #E5E7EB', borderRadius: '8px' }}
          />
          <Area
            type="monotone"
            dataKey="gpt4"
            stackId="1"
            stroke="#8B5CF6"
            fill="#8B5CF6"
            fillOpacity={0.6}
          />
          <Area
            type="monotone"
            dataKey="gpt35"
            stackId="1"
            stroke="#6366F1"
            fill="#6366F1"
            fillOpacity={0.6}
          />
          <Area
            type="monotone"
            dataKey="claude"
            stackId="1"
            stroke="#EC4899"
            fill="#EC4899"
            fillOpacity={0.6}
          />
          <Area
            type="monotone"
            dataKey="embeddings"
            stackId="1"
            stroke="#10B981"
            fill="#10B981"
            fillOpacity={0.6}
          />
        </AreaChart>
      </ResponsiveContainer>

      <div className="mt-4 flex gap-4 text-sm">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded-full bg-[#8B5CF6]" />
          <span>GPT-4</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded-full bg-[#6366F1]" />
          <span>GPT-3.5</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded-full bg-[#EC4899]" />
          <span>Claude</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded-full bg-[#10B981]" />
          <span>Embeddings</span>
        </div>
      </div>
    </div>
  )
}
```

---

## 4. Performance Page

**Route:** `/performance`
**File:** `app/(dashboard)/performance/page.tsx`

### Key Charts

#### 4.1 Latency Percentiles Chart

```tsx
// components/performance/LatencyChart.tsx
'use client'

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

export function LatencyChart() {
  const { data } = useQuery({
    queryKey: ['performance-latency'],
    queryFn: () => apiClient.get('/metrics/performance/latency?range=1h'),
    refetchInterval: 60000, // Refetch every minute
  })

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Latency Percentiles (Last Hour)</h3>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data?.timeseries || []}>
          <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
          <XAxis
            dataKey="timestamp"
            tickFormatter={(value) => new Date(value).toLocaleTimeString()}
            stroke="#6B7280"
          />
          <YAxis stroke="#6B7280" label={{ value: 'Latency (s)', angle: -90, position: 'insideLeft' }} />
          <Tooltip />
          <Legend />
          <Line type="monotone" dataKey="p50" stroke="#10B981" strokeWidth={2} name="P50" dot={false} />
          <Line type="monotone" dataKey="p90" stroke="#F59E0B" strokeWidth={2} name="P90" dot={false} />
          <Line type="monotone" dataKey="p95" stroke="#EF4444" strokeWidth={2} name="P95" dot={false} />
          <Line type="monotone" dataKey="p99" stroke="#DC2626" strokeWidth={2} name="P99" dot={false} />
        </LineChart>
      </ResponsiveContainer>

      <div className="mt-4 grid grid-cols-4 gap-4">
        <div>
          <p className="text-xs text-gray-600">P50</p>
          <p className="text-lg font-semibold">{data?.current?.p50}s</p>
        </div>
        <div>
          <p className="text-xs text-gray-600">P90</p>
          <p className="text-lg font-semibold">{data?.current?.p90}s</p>
        </div>
        <div>
          <p className="text-xs text-gray-600">P95</p>
          <p className="text-lg font-semibold">{data?.current?.p95}s</p>
        </div>
        <div>
          <p className="text-xs text-gray-600">P99</p>
          <p className="text-lg font-semibold text-rose-600">{data?.current?.p99}s</p>
        </div>
      </div>
    </div>
  )
}
```

#### 4.2 Latency Heatmap

```tsx
// components/performance/LatencyHeatmap.tsx
'use client'

export function LatencyHeatmap() {
  const { data } = useQuery({
    queryKey: ['performance-heatmap'],
    queryFn: () => apiClient.get('/metrics/performance/heatmap?range=24h'),
  })

  // Heatmap data: agents × hourly buckets
  const getColor = (latency: number) => {
    if (latency < 1) return '#10B981' // Green
    if (latency < 2) return '#F59E0B' // Amber
    if (latency < 4) return '#F97316' // Orange
    return '#EF4444' // Red
  }

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Latency Heatmap (By Hour & Agent)</h3>

      <div className="overflow-x-auto">
        <div className="inline-block min-w-full">
          {/* Hour labels */}
          <div className="flex">
            <div className="w-32" /> {/* Agent name column */}
            {Array.from({ length: 24 }, (_, i) => (
              <div key={i} className="flex-1 text-xs text-center text-gray-600">
                {i}:00
              </div>
            ))}
          </div>

          {/* Agent rows */}
          {data?.agents?.map((agent) => (
            <div key={agent.name} className="flex items-center">
              <div className="w-32 text-sm text-gray-700 truncate">{agent.name}</div>
              {agent.hourlyLatency.map((latency, hour) => (
                <div
                  key={hour}
                  className="flex-1 h-10 border border-gray-200 cursor-pointer hover:opacity-75 transition-opacity"
                  style={{ backgroundColor: getColor(latency) }}
                  title={`${agent.name} at ${hour}:00 - ${latency}s`}
                />
              ))}
            </div>
          ))}
        </div>
      </div>

      <div className="mt-4 flex items-center gap-4 text-xs">
        <span className="text-gray-600">Latency:</span>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 rounded bg-[#10B981]" />
          <span>&lt;1s</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 rounded bg-[#F59E0B]" />
          <span>1-2s</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 rounded bg-[#F97316]" />
          <span>2-4s</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 rounded bg-[#EF4444]" />
          <span>&gt;4s</span>
        </div>
      </div>
    </div>
  )
}
```

---

## 5. Quality Page

**Route:** `/quality`
**File:** `app/(dashboard)/quality/page.tsx`

### Key Components

#### 5.1 Quality Radar Chart

```tsx
// components/quality/QualityRadarChart.tsx
'use client'

import { RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar, ResponsiveContainer } from 'recharts'

export function QualityRadarChart() {
  const { data } = useQuery({
    queryKey: ['quality-dimensions'],
    queryFn: () => apiClient.get('/metrics/quality/dimensions'),
  })

  const radarData = [
    { dimension: 'Accuracy', value: data?.accuracy || 0 },
    { dimension: 'Relevance', value: data?.relevance || 0 },
    { dimension: 'Helpfulness', value: data?.helpfulness || 0 },
    { dimension: 'Groundedness', value: data?.groundedness || 0 },
    { dimension: 'Coherence', value: data?.coherence || 0 },
  ]

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Quality Dimensions</h3>
      <ResponsiveContainer width="100%" height={300}>
        <RadarChart data={radarData}>
          <PolarGrid stroke="#E5E7EB" />
          <PolarAngleAxis dataKey="dimension" stroke="#6B7280" />
          <PolarRadiusAxis angle={90} domain={[0, 100]} stroke="#6B7280" />
          <Radar
            name="Quality"
            dataKey="value"
            stroke="#6366F1"
            fill="#6366F1"
            fillOpacity={0.6}
          />
        </RadarChart>
      </ResponsiveContainer>
    </div>
  )
}
```

#### 5.2 Sentiment Donut Chart

```tsx
// components/quality/SentimentChart.tsx
'use client'

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts'

export function SentimentChart() {
  const { data } = useQuery({
    queryKey: ['feedback-sentiment'],
    queryFn: () => apiClient.get('/metrics/quality/sentiment'),
  })

  const chartData = [
    { name: 'Positive', value: data?.positive || 0, color: '#10B981' },
    { name: 'Neutral', value: data?.neutral || 0, color: '#6B7280' },
    { name: 'Negative', value: data?.negative || 0, color: '#EF4444' },
  ]

  return (
    <div className="bg-white rounded-lg shadow-card p-6">
      <h3 className="text-lg font-semibold mb-4">Sentiment Analysis</h3>
      <ResponsiveContainer width="100%" height={250}>
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={90}
            paddingAngle={2}
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip />
        </PieChart>
      </ResponsiveContainer>

      <div className="mt-4 space-y-2">
        {chartData.map((item) => (
          <div key={item.name} className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }} />
              <span className="text-sm">{item.name}</span>
            </div>
            <span className="text-sm font-semibold">{item.value}%</span>
          </div>
        ))}
      </div>
    </div>
  )
}
```

---

## 6. Safety Page

**Route:** `/safety`
**File:** `app/(dashboard)/safety/page.tsx`

### Key Components

#### 6.1 Guardrail Status Cards

```tsx
// components/safety/GuardrailCard.tsx
'use client'

import { Shield, Settings, BarChart3, Edit } from 'lucide-react'
import { Switch } from '@/components/ui/switch'

interface GuardrailCardProps {
  guardrail: {
    id: string
    name: string
    description: string
    enabled: boolean
    appliedTo: string[]
    triggeredToday: number
    latency: number
    successRate: number
  }
}

export function GuardrailCard({ guardrail }: GuardrailCardProps) {
  const [enabled, setEnabled] = useState(guardrail.enabled)

  const handleToggle = async () => {
    await apiClient.patch(`/guardrails/${guardrail.id}`, { enabled: !enabled })
    setEnabled(!enabled)
  }

  return (
    <div className="bg-white rounded-lg shadow-card p-6 border-l-4 border-primary-500">
      <div className="flex items-start justify-between">
        <div className="flex items-start gap-3">
          <Shield className="h-6 w-6 text-primary-600 mt-1" />
          <div>
            <h3 className="font-semibold">{guardrail.name}</h3>
            <p className="text-sm text-gray-600 mt-1">{guardrail.description}</p>
          </div>
        </div>
        <Switch checked={enabled} onCheckedChange={handleToggle} />
      </div>

      <div className="mt-4 pt-4 border-t">
        <p className="text-sm text-gray-600">Applied to: {guardrail.appliedTo.join(', ')}</p>
        <div className="mt-2 flex items-center gap-4 text-sm">
          <span>Triggered: <strong>{guardrail.triggeredToday} times today</strong></span>
          <span>•</span>
          <span>Latency: <strong>{guardrail.latency}ms</strong></span>
          <span>•</span>
          <span>Success: <strong>{guardrail.successRate}%</strong></span>
        </div>
      </div>

      <div className="mt-4 flex gap-2">
        <Button variant="outline" size="sm">
          <Settings className="h-4 w-4 mr-1" />
          Configure
        </Button>
        <Button variant="outline" size="sm">
          <BarChart3 className="h-4 w-4 mr-1" />
          View Logs
        </Button>
        <Button variant="outline" size="sm">
          <Edit className="h-4 w-4 mr-1" />
          Edit
        </Button>
      </div>
    </div>
  )
}
```

---

## 7. Impact Page

**Route:** `/impact`
**File:** `app/(dashboard)/impact/page.tsx`

### Key Components

#### 7.1 ROI Dashboard

```tsx
// components/impact/ROIDashboard.tsx
'use client'

export function ROIDashboard() {
  const { data } = useQuery({
    queryKey: ['impact-roi'],
    queryFn: () => apiClient.get('/metrics/impact/roi'),
  })

  return (
    <div className="bg-gradient-to-br from-primary-50 to-blue-50 rounded-lg shadow-card p-8">
      <h3 className="text-lg font-semibold mb-6">Return on Investment</h3>

      <div className="grid grid-cols-2 gap-6">
        <div>
          <p className="text-sm text-gray-600">Total AI Spend (30d)</p>
          <p className="text-3xl font-bold text-gray-900">${data?.spend?.toFixed(2)}</p>
        </div>
        <div>
          <p className="text-sm text-gray-600">Value Generated</p>
          <p className="text-3xl font-bold text-emerald-600">
            ${data?.valueGenerated?.toLocaleString()}
          </p>
        </div>
      </div>

      <div className="mt-6 p-6 bg-white rounded-lg">
        <p className="text-sm text-gray-600 mb-1">ROI</p>
        <p className="text-5xl font-bold text-primary-600">{data?.roi?.toLocaleString()}×</p>
      </div>

      <div className="mt-6 grid grid-cols-2 gap-4">
        <div className="p-4 bg-white rounded-lg">
          <p className="text-xs text-gray-600">Payback Period</p>
          <p className="text-lg font-semibold">{data?.paybackPeriod}</p>
        </div>
        <div className="p-4 bg-white rounded-lg">
          <p className="text-xs text-gray-600">Monthly Savings</p>
          <p className="text-lg font-semibold">${data?.monthlySavings?.toLocaleString()}</p>
        </div>
      </div>

      <div className="mt-4 flex gap-2">
        <Button variant="outline" size="sm">View Methodology</Button>
        <Button variant="outline" size="sm">Customize Metrics</Button>
      </div>
    </div>
  )
}
```

#### 7.2 Goal Progress Cards

```tsx
// components/impact/GoalTracker.tsx
'use client'

export function GoalTracker() {
  const { data: goals } = useQuery({
    queryKey: ['impact-goals'],
    queryFn: () => apiClient.get('/goals'),
  })

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold">Goal Tracking</h3>

      {goals?.map((goal) => (
        <div key={goal.id} className="bg-white rounded-lg shadow-card p-6">
          <h4 className="font-semibold">{goal.title}</h4>
          <p className="text-sm text-gray-600 mt-1">
            Target: {goal.baseline} → {goal.target} by {goal.deadline}
          </p>

          <div className="mt-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium">
                Current Progress: {goal.current} ({goal.percentageReduction}% reduction)
              </span>
              <span className="text-sm text-gray-600">{goal.percentageToGoal}% to goal</span>
            </div>

            <div className="relative h-3 bg-gray-200 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all ${
                  goal.status === 'on-track' ? 'bg-emerald-500' :
                  goal.status === 'at-risk' ? 'bg-amber-500' :
                  'bg-rose-500'
                }`}
                style={{ width: `${goal.percentageToGoal}%` }}
              />
            </div>
          </div>

          <p className="text-sm text-gray-600 mt-3">{goal.statusMessage}</p>

          <div className="mt-4 flex gap-2">
            <Button variant="outline" size="sm">View Funnel Analysis</Button>
            <Button variant="outline" size="sm">Edit Goal</Button>
          </div>
        </div>
      ))}

      <Button variant="outline" className="w-full">
        + Create New Goal
      </Button>
    </div>
  )
}
```

---

## 8. Settings Page

**Route:** `/settings`
**File:** `app/(dashboard)/settings/page.tsx`

### Component Structure

```tsx
// app/(dashboard)/settings/page.tsx
export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-semibold">Settings</h1>

      <Tabs defaultValue="workspace">
        <TabsList>
          <TabsTrigger value="workspace">Workspace</TabsTrigger>
          <TabsTrigger value="team">Team</TabsTrigger>
          <TabsTrigger value="integrations">Integrations</TabsTrigger>
          <TabsTrigger value="billing">Billing</TabsTrigger>
          <TabsTrigger value="security">Security</TabsTrigger>
        </TabsList>

        <TabsContent value="workspace">
          <WorkspaceSettings />
        </TabsContent>

        <TabsContent value="team">
          <TeamManagement />
        </TabsContent>

        <TabsContent value="integrations">
          <IntegrationsPanel />
        </TabsContent>

        <TabsContent value="billing">
          <BillingPanel />
        </TabsContent>
      </Tabs>
    </div>
  )
}
```

---

## 9. Shared Components

### 9.1 Data Table

```tsx
// components/dashboard/DataTable.tsx
'use client'

import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  flexRender,
} from '@tanstack/react-table'

interface DataTableProps<TData> {
  columns: any[]
  data: TData[]
  searchPlaceholder?: string
}

export function DataTable<TData>({ columns, data, searchPlaceholder }: DataTableProps<TData>) {
  const [sorting, setSorting] = useState([])
  const [globalFilter, setGlobalFilter] = useState('')

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    state: {
      sorting,
      globalFilter,
    },
    onSortingChange: setSorting,
    onGlobalFilterChange: setGlobalFilter,
  })

  return (
    <div className="space-y-4">
      <Input
        placeholder={searchPlaceholder || "Search..."}
        value={globalFilter}
        onChange={(e) => setGlobalFilter(e.target.value)}
        className="max-w-sm"
      />

      <div className="rounded-lg border bg-white overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            {table.getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <th key={header.id} className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    {flexRender(header.column.columnDef.header, header.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody className="divide-y divide-gray-200">
            {table.getRowModel().rows.map((row) => (
              <tr key={row.id} className="hover:bg-gray-50 cursor-pointer">
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} className="px-4 py-3 text-sm">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

---

## Summary

This specification provides implementation-ready details for all 8 pages:

1. **Home** - KPI cards, alerts feed, activity stream
2. **Usage** - Time series, bar charts, geographic map
3. **Cost** - Budget progress, stacked area chart, breakdown
4. **Performance** - Latency percentiles, heatmap, error monitoring
5. **Quality** - Radar chart, sentiment donut, evaluation history
6. **Safety** - Guardrail cards, violation logs, audit trail
7. **Impact** - ROI dashboard, goal trackers
8. **Settings** - Workspace, team, integrations, billing

All components use:
- **Recharts** for data visualization
- **TanStack Query** for data fetching
- **TypeScript** for type safety
- **shadcn/ui + Tailwind** for styling
- **Real-time updates** where appropriate

Next: Review backend-services-architecture.md for API contract details.
