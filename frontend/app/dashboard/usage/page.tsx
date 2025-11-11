'use client'
export const dynamic = 'force-dynamic'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { KPICard } from '@/components/dashboard/KPICard'
import { Button } from '@/components/ui/button'
import { FilterBar } from '@/components/filters/FilterBar'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { TrendingUp, TrendingDown, Minus, AlertTriangle, Users, Target } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'
import { UserSegmentCards } from '@/components/usage/UserSegmentCards'
import { IntentDistributionMatrix } from '@/components/usage/IntentDistributionMatrix'
import { RetentionCohortTable } from '@/components/usage/RetentionCohortTable'
import { AgentAdoptionCurves } from '@/components/usage/AgentAdoptionCurves'
import { TimeOfDayHeatmap } from '@/components/usage/TimeOfDayHeatmap'
import { TopUsersTable } from '@/components/usage/TopUsersTable'

interface UsageOverview {
  total_calls: number
  unique_users: number
  active_agents: number
  avg_calls_per_user: number
  change_from_previous: {
    total_calls: number
    unique_users: number
    active_agents: number
  }
}

interface CallsOverTimeItem {
  timestamp: string
  agent_id: string
  call_count: number
  avg_latency_ms: number
  total_cost_usd: number
}

interface AgentDistributionItem {
  agent_id: string
  call_count: number
  percentage: number
  avg_latency_ms: number
  error_rate: number
}


const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82ca9d', '#ffc658']

const TrendIcon = ({ change }: { change: number }) => {
  if (change > 0) return <TrendingUp className="h-4 w-4 text-green-500" />
  if (change < 0) return <TrendingDown className="h-4 w-4 text-red-500" />
  return <Minus className="h-4 w-4 text-gray-500" />
}

export default function UsagePage() {
  const { user } = useAuth()
  const { filters } = useFilters()

  // Fetch usage overview
  const { data: overview, isLoading: overviewLoading, error: overviewError } = useQuery({
    queryKey: ['usage-overview', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/usage/overview?range=${filters.range}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as UsageOverview
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000, // Refetch every 30s
  })

  // Fetch calls over time
  const { data: callsOverTime, isLoading: callsLoading } = useQuery({
    queryKey: ['calls-over-time', filters.range],
    queryFn: async () => {
      const granularity = filters.range === '1h' ? 'hourly' : filters.range === '24h' ? 'hourly' : 'daily'
      const response = await apiClient.get(
        `/api/v1/usage/calls-over-time?range=${filters.range}&granularity=${granularity}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as CallsOverTimeItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Fetch agent distribution
  const { data: agentDist, isLoading: agentLoading } = useQuery({
    queryKey: ['agent-distribution', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/agent-distribution?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as AgentDistributionItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })


  // Aggregate calls over time by timestamp (sum across agents)
  const aggregatedCalls = callsOverTime?.reduce((acc, item) => {
    const existing = acc.find(a => a.timestamp === item.timestamp)
    if (existing) {
      existing.call_count += item.call_count
    } else {
      acc.push({ timestamp: item.timestamp, call_count: item.call_count })
    }
    return acc
  }, [] as { timestamp: string; call_count: number }[])
    ?.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())

  // Process agent distribution - show top 10 and group rest as "Others"
  const processedAgentDist = agentDist ? (() => {
    if (agentDist.length <= 10) return agentDist

    const top10 = agentDist.slice(0, 10)
    const others = agentDist.slice(10)
    const othersPercentage = others.reduce((sum, item) => sum + item.percentage, 0)
    const othersCallCount = others.reduce((sum, item) => sum + item.call_count, 0)

    return [
      ...top10,
      {
        agent_id: 'Others',
        call_count: othersCallCount,
        percentage: othersPercentage,
        avg_latency_ms: 0,
        error_rate: 0
      }
    ]
  })() : []

  if (overviewError) {
    return (
      <div>
        <FilterBar />
        <div className="p-8">
          <h1 className="text-3xl font-bold mb-6">Usage Analytics</h1>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load usage analytics. Please try again later.
            </AlertDescription>
          </Alert>
        </div>
      </div>
    )
  }

  return (
    <div>
      {/* Global Filter Bar */}
      <FilterBar />

      <div className="p-8 space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold">Usage Analytics</h1>
          <p className="text-muted-foreground">
            Track adoption, engagement patterns, and agent portfolio utilization across the organization
          </p>
        </div>

      {/* KPI Cards Row 1 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          title="Total API Calls"
          value={overview?.total_calls.toLocaleString() || '—'}
          change={overview?.change_from_previous.total_calls || 0}
          changeLabel="vs last period"
          trend="normal"
          loading={overviewLoading}
        />
        <KPICard
          title="Unique Users"
          value={overview?.unique_users.toLocaleString() || '—'}
          change={overview?.change_from_previous.unique_users || 0}
          changeLabel="vs last period"
          trend="normal"
          loading={overviewLoading}
        />
        <KPICard
          title="Active Agents"
          value={overview?.active_agents.toLocaleString() || '—'}
          change={overview?.change_from_previous.active_agents || 0}
          changeLabel="vs last period"
          trend="normal"
          loading={overviewLoading}
        />
        <KPICard
          title="Avg Calls/User"
          value={overview ? overview.avg_calls_per_user.toFixed(1) : '—'}
          change={0}
          changeLabel="vs last period"
          trend="normal"
          loading={overviewLoading}
        />
      </div>

      {/* KPI Cards Row 2 - User Segments */}
      <UserSegmentCards />

      {/* API Calls Over Time */}
      <Card>
        <CardHeader>
          <CardTitle>API Calls Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          {callsLoading ? (
            <Skeleton className="h-[300px] w-full" />
          ) : aggregatedCalls && aggregatedCalls.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={aggregatedCalls}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="timestamp"
                  tickFormatter={(value) => new Date(value).toLocaleTimeString([], {
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                />
                <YAxis />
                <Tooltip
                  labelFormatter={(value) => new Date(value).toLocaleString()}
                  formatter={(value: number) => [value.toLocaleString(), 'Calls']}
                />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="call_count"
                  stroke="#8884d8"
                  strokeWidth={2}
                  name="API Calls"
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              No data available for the selected time range
            </div>
          )}
        </CardContent>
      </Card>

      {/* Agent Distribution - Horizontal Bar Chart */}
      <Card>
        <CardHeader>
          <CardTitle>Agent Distribution</CardTitle>
          <p className="text-sm text-muted-foreground">Top agents by API call volume</p>
        </CardHeader>
        <CardContent>
          {agentLoading ? (
            <Skeleton className="h-[400px] w-full" />
          ) : processedAgentDist && processedAgentDist.length > 0 ? (
            <div className="space-y-2">
              <ResponsiveContainer width="100%" height={400}>
                <BarChart
                  data={processedAgentDist}
                  layout="vertical"
                  margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" horizontal={true} vertical={false} />
                  <XAxis type="number" unit="%" />
                  <YAxis
                    type="category"
                    dataKey="agent_id"
                    width={200}
                    tick={{ fontSize: 12 }}
                    tickFormatter={(value) => value.length > 28 ? value.substring(0, 28) + '...' : value}
                  />
                  <Tooltip
                    formatter={(value: number, name: string, props: any) => [
                      `${value.toFixed(1)}% (${props.payload.call_count.toLocaleString()} calls)`,
                      'Usage'
                    ]}
                    labelFormatter={(label) => `Agent: ${label}`}
                  />
                  <Bar dataKey="percentage" fill="#8884d8" radius={[0, 4, 4, 0]}>
                    {processedAgentDist.map((_, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
              {agentDist && agentDist.length > 10 && (
                <p className="text-xs text-muted-foreground text-center mt-2">
                  Showing top 10 agents. {agentDist.length - 10} others grouped as "Others" ({(agentDist.slice(10).reduce((sum, a) => sum + a.percentage, 0)).toFixed(1)}%)
                </p>
              )}
            </div>
          ) : (
            <div className="h-[400px] flex items-center justify-center text-muted-foreground">
              No agent data available
            </div>
          )}
        </CardContent>
      </Card>

      {/* Top Users Table */}
      <TopUsersTable />

      {/* Intent Distribution Matrix */}
      <IntentDistributionMatrix />

      {/* Retention Cohort Table */}
      <RetentionCohortTable />

      {/* Agent Adoption Curves */}
      <AgentAdoptionCurves />

      {/* Time-of-Day Usage Heatmap */}
      <TimeOfDayHeatmap />
      </div>
    </div>
  )
}
