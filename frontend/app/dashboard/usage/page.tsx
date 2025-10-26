'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { KPICard } from '@/components/dashboard/KPICard'
import { TimeRangeSelector } from '@/components/dashboard/TimeRangeSelector'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

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

interface TopUsersItem {
  user_id: string
  total_calls: number
  agents_used: number
  last_active: string
  trend: 'up' | 'down' | 'stable'
  change_percentage: number
}

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82ca9d', '#ffc658']

export default function UsagePage() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('7d')

  // Fetch usage overview
  const { data: overview, isLoading: overviewLoading, error: overviewError } = useQuery({
    queryKey: ['usage-overview', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/usage/overview?range=${timeRange}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as UsageOverview
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000, // Refetch every 30s
  })

  // Fetch calls over time
  const { data: callsOverTime, isLoading: callsLoading } = useQuery({
    queryKey: ['calls-over-time', timeRange],
    queryFn: async () => {
      const granularity = timeRange === '1h' ? 'hourly' : timeRange === '24h' ? 'hourly' : 'daily'
      const response = await apiClient.get(
        `/api/v1/usage/calls-over-time?range=${timeRange}&granularity=${granularity}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as CallsOverTimeItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Fetch agent distribution
  const { data: agentDist, isLoading: agentLoading } = useQuery({
    queryKey: ['agent-distribution', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/agent-distribution?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as AgentDistributionItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Fetch top users
  const { data: topUsers, isLoading: usersLoading } = useQuery({
    queryKey: ['top-users', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/top-users?range=${timeRange}&limit=10`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as TopUsersItem[]
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
    .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())

  const TrendIcon = ({ change }: { change: number }) => {
    if (change > 0) return <TrendingUp className="h-4 w-4 text-green-500" />
    if (change < 0) return <TrendingDown className="h-4 w-4 text-red-500" />
    return <Minus className="h-4 w-4 text-gray-500" />
  }

  if (overviewError) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-6">Usage Analytics</h1>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load usage analytics. Please try again later.
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  return (
    <div className="p-8 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Usage Analytics</h1>
          <p className="text-muted-foreground">
            Track API call volume, active users, and agent distribution
          </p>
        </div>
        <TimeRangeSelector value={timeRange} onChange={setTimeRange} />
      </div>

      {/* KPI Cards */}
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

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Agent Distribution */}
        <Card>
          <CardHeader>
            <CardTitle>Agent Distribution</CardTitle>
          </CardHeader>
          <CardContent>
            {agentLoading ? (
              <Skeleton className="h-[300px] w-full" />
            ) : agentDist && agentDist.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={agentDist}
                    dataKey="percentage"
                    nameKey="agent_id"
                    cx="50%"
                    cy="50%"
                    outerRadius={100}
                    label={(entry) => `${entry.agent_id}: ${entry.percentage.toFixed(1)}%`}
                  >
                    {agentDist.map((_, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip
                    formatter={(value: number) => [`${value.toFixed(1)}%`, 'Distribution']}
                  />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                No agent data available
              </div>
            )}
          </CardContent>
        </Card>

        {/* Top Users */}
        <Card>
          <CardHeader>
            <CardTitle>Top Users</CardTitle>
          </CardHeader>
          <CardContent>
            {usersLoading ? (
              <Skeleton className="h-[300px] w-full" />
            ) : topUsers && topUsers.length > 0 ? (
              <div className="overflow-auto max-h-[300px]">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>User ID</TableHead>
                      <TableHead className="text-right">Calls</TableHead>
                      <TableHead className="text-right">Agents</TableHead>
                      <TableHead className="text-right">Trend</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {topUsers.map((user, idx) => (
                      <TableRow key={idx}>
                        <TableCell className="font-mono text-sm">
                          {user.user_id.substring(0, 8)}...
                        </TableCell>
                        <TableCell className="text-right">
                          {user.total_calls.toLocaleString()}
                        </TableCell>
                        <TableCell className="text-right">
                          {user.agents_used}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex items-center justify-end gap-1">
                            <TrendIcon change={user.change_percentage} />
                            <span className="text-sm text-muted-foreground">
                              {Math.abs(user.change_percentage).toFixed(0)}%
                            </span>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            ) : (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                No user data available
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
