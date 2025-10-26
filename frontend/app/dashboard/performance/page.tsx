'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { KPICard } from '@/components/dashboard/KPICard'
import { TimeRangeSelector } from '@/components/dashboard/TimeRangeSelector'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { AlertCircle, TrendingUp } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface PerformanceOverview {
  p50_latency_ms: number
  p95_latency_ms: number
  p99_latency_ms: number
  avg_latency_ms: number
  error_rate: number
  success_rate: number
  total_requests: number
  requests_per_second: number
}

interface LatencyPercentilesItem {
  timestamp: string
  p50: number
  p95: number
  p99: number
  avg: number
}

interface ThroughputItem {
  timestamp: string
  success_count: number
  error_count: number
  timeout_count: number
  total_count: number
  requests_per_second: number
}

interface ErrorAnalysisItem {
  agent_id: string
  error_type: string
  error_count: number
  error_rate: number
  last_occurrence: string
  sample_error_message?: string
}

export default function PerformancePage() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('7d')

  // Fetch performance overview
  const { data: overview, isLoading: overviewLoading, error: overviewError } = useQuery({
    queryKey: ['performance-overview', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/performance/overview?range=${timeRange}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as PerformanceOverview
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000, // Refetch every 30s
  })

  // Fetch latency percentiles
  const { data: latencyData, isLoading: latencyLoading } = useQuery({
    queryKey: ['latency-percentiles', timeRange],
    queryFn: async () => {
      const granularity = timeRange === '1h' ? 'hourly' : timeRange === '24h' ? 'hourly' : 'daily'
      const response = await apiClient.get(
        `/api/v1/performance/latency?range=${timeRange}&granularity=${granularity}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as LatencyPercentilesItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Fetch throughput
  const { data: throughputData, isLoading: throughputLoading } = useQuery({
    queryKey: ['throughput', timeRange],
    queryFn: async () => {
      const granularity = timeRange === '1h' ? 'hourly' : timeRange === '24h' ? 'hourly' : 'daily'
      const response = await apiClient.get(
        `/api/v1/performance/throughput?range=${timeRange}&granularity=${granularity}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as ThroughputItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Fetch error analysis
  const { data: errorData, isLoading: errorLoading } = useQuery({
    queryKey: ['error-analysis', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/performance/errors?range=${timeRange}&limit=10`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as { data: ErrorAnalysisItem[]; total_errors: number; overall_error_rate: number }
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Sort data by timestamp
  const sortedLatency = latencyData?.sort((a, b) =>
    new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
  )

  const sortedThroughput = throughputData?.sort((a, b) =>
    new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
  )

  if (overviewError) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-6">Performance Monitoring</h1>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load performance data. Please try again later.
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
          <h1 className="text-3xl font-bold">Performance Monitoring</h1>
          <p className="text-muted-foreground">
            Track latency, throughput, and error rates across your agents
          </p>
        </div>
        <TimeRangeSelector value={timeRange} onChange={setTimeRange} />
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          title="P50 Latency"
          value={overview ? `${Math.round(overview.p50_latency_ms)}ms` : '—'}
          change={0}
          changeLabel="median response time"
          trend="inverse"
          loading={overviewLoading}
        />
        <KPICard
          title="P95 Latency"
          value={overview ? `${Math.round(overview.p95_latency_ms)}ms` : '—'}
          change={0}
          changeLabel="95th percentile"
          trend="inverse"
          loading={overviewLoading}
        />
        <KPICard
          title="P99 Latency"
          value={overview ? `${Math.round(overview.p99_latency_ms)}ms` : '—'}
          change={0}
          changeLabel="99th percentile"
          trend="inverse"
          loading={overviewLoading}
        />
        <KPICard
          title="Error Rate"
          value={overview ? `${overview.error_rate.toFixed(2)}%` : '—'}
          change={0}
          changeLabel={`${overview?.total_requests.toLocaleString() || 0} total requests`}
          trend="inverse"
          loading={overviewLoading}
        />
      </div>

      {/* Latency Percentiles Over Time */}
      <Card>
        <CardHeader>
          <CardTitle>Latency Percentiles Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          {latencyLoading ? (
            <Skeleton className="h-[300px] w-full" />
          ) : sortedLatency && sortedLatency.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={sortedLatency}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="timestamp"
                  tickFormatter={(value) => new Date(value).toLocaleTimeString([], {
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                />
                <YAxis label={{ value: 'Latency (ms)', angle: -90, position: 'insideLeft' }} />
                <Tooltip
                  labelFormatter={(value) => new Date(value).toLocaleString()}
                  formatter={(value: number) => [`${Math.round(value)}ms`, '']}
                />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="p50"
                  stroke="#82ca9d"
                  strokeWidth={2}
                  name="P50"
                  dot={false}
                />
                <Line
                  type="monotone"
                  dataKey="p95"
                  stroke="#8884d8"
                  strokeWidth={2}
                  name="P95"
                  dot={false}
                />
                <Line
                  type="monotone"
                  dataKey="p99"
                  stroke="#ff8042"
                  strokeWidth={2}
                  name="P99"
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              No latency data available for the selected time range
            </div>
          )}
        </CardContent>
      </Card>

      {/* Throughput Over Time */}
      <Card>
        <CardHeader>
          <CardTitle>Request Throughput by Status</CardTitle>
        </CardHeader>
        <CardContent>
          {throughputLoading ? (
            <Skeleton className="h-[300px] w-full" />
          ) : sortedThroughput && sortedThroughput.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={sortedThroughput}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="timestamp"
                  tickFormatter={(value) => new Date(value).toLocaleTimeString([], {
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                />
                <YAxis label={{ value: 'Request Count', angle: -90, position: 'insideLeft' }} />
                <Tooltip
                  labelFormatter={(value) => new Date(value).toLocaleString()}
                  formatter={(value: number) => [value.toLocaleString(), '']}
                />
                <Legend />
                <Area
                  type="monotone"
                  dataKey="success_count"
                  stackId="1"
                  stroke="#82ca9d"
                  fill="#82ca9d"
                  name="Success"
                />
                <Area
                  type="monotone"
                  dataKey="error_count"
                  stackId="1"
                  stroke="#ff8042"
                  fill="#ff8042"
                  name="Error"
                />
                <Area
                  type="monotone"
                  dataKey="timeout_count"
                  stackId="1"
                  stroke="#ffc658"
                  fill="#ffc658"
                  name="Timeout"
                />
              </AreaChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              No throughput data available for the selected time range
            </div>
          )}
        </CardContent>
      </Card>

      {/* Error Analysis */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Error Analysis</CardTitle>
            <Badge variant={errorData && errorData.overall_error_rate > 5 ? 'destructive' : 'secondary'}>
              {errorData ? `${errorData.overall_error_rate.toFixed(2)}%` : '—'} Overall Error Rate
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          {errorLoading ? (
            <Skeleton className="h-[300px] w-full" />
          ) : errorData && errorData.data.length > 0 ? (
            <div className="overflow-auto max-h-[400px]">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Agent ID</TableHead>
                    <TableHead>Error Type</TableHead>
                    <TableHead className="text-right">Count</TableHead>
                    <TableHead className="text-right">Rate</TableHead>
                    <TableHead>Last Seen</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {errorData.data.map((error, idx) => (
                    <TableRow key={idx}>
                      <TableCell className="font-mono text-sm">
                        {error.agent_id.substring(0, 12)}...
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <AlertCircle className="h-4 w-4 text-destructive" />
                          <span className="font-medium text-sm">{error.error_type}</span>
                        </div>
                        {error.sample_error_message && (
                          <p className="text-xs text-muted-foreground mt-1 truncate max-w-[200px]">
                            {error.sample_error_message}
                          </p>
                        )}
                      </TableCell>
                      <TableCell className="text-right font-medium">
                        {error.error_count.toLocaleString()}
                      </TableCell>
                      <TableCell className="text-right">
                        <Badge variant={error.error_rate > 10 ? 'destructive' : 'secondary'}>
                          {error.error_rate.toFixed(1)}%
                        </Badge>
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {new Date(error.last_occurrence).toLocaleString()}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              <div className="text-center space-y-2">
                <TrendingUp className="h-12 w-12 mx-auto text-green-500" />
                <p className="font-medium">No errors detected</p>
                <p className="text-sm">All requests completed successfully</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Performance Summary */}
      {overview && (
        <Card>
          <CardHeader>
            <CardTitle>Performance Summary</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Average Latency</p>
                <p className="text-2xl font-bold">{Math.round(overview.avg_latency_ms)}ms</p>
              </div>
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Success Rate</p>
                <p className="text-2xl font-bold text-green-600">{overview.success_rate.toFixed(1)}%</p>
              </div>
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Requests/Second</p>
                <p className="text-2xl font-bold">{overview.requests_per_second.toFixed(2)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
