'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ReferenceDot, Area, ComposedChart } from 'recharts'
import { AlertTriangle, Bell, TrendingUp, Clock } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'

interface Anomaly {
  timestamp: string
  actual_cost: number
  expected_cost: number
  deviation_percentage: number
  severity: 'low' | 'medium' | 'high' | 'critical'
  reason: string
  agent_id?: string
}

interface TimelineDataPoint {
  timestamp: string
  actual_cost: number
  expected_cost: number
  upper_bound: number
  lower_bound: number
}

interface AnomalyData {
  timeline: TimelineDataPoint[]
  anomalies: Anomaly[]
  total_anomalies: number
  critical_anomalies: number
}

/**
 * CostAnomalyTimeline - Unusual spending pattern detection
 *
 * Displays cost timeline with anomaly detection:
 * - Expected cost baseline with confidence bands
 * - Actual costs overlaid
 * - Anomaly markers with severity indicators
 * - Detailed anomaly table with root causes
 *
 * Uses statistical analysis to detect unusual spending patterns.
 *
 * PRD Tab 3: Chart 3.6 - Cost Anomaly Timeline (P1)
 */
export function CostAnomalyTimeline() {
  const { user } = useAuth()
  const { filters } = useFilters()

  const { data, isLoading, error } = useQuery({
    queryKey: ['cost-anomalies', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/anomalies?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as AnomalyData
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 300000, // Refetch every 5 minutes
  })

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      const anomaly = data.anomaly

      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg max-w-xs">
          <p className="font-semibold text-sm mb-2">
            {new Date(label).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
          </p>
          <div className="space-y-1 text-xs">
            <p>
              <span className="text-muted-foreground">Actual:</span>
              <span className="font-medium ml-2">${data.actual_cost.toFixed(2)}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Expected:</span>
              <span className="font-medium ml-2">${data.expected_cost.toFixed(2)}</span>
            </p>
            {anomaly && (
              <>
                <p className="text-red-600 font-medium mt-2">
                  ⚠ Anomaly Detected
                </p>
                <p>
                  <span className="text-muted-foreground">Deviation:</span>
                  <span className="font-medium ml-2">{anomaly.deviation_percentage.toFixed(1)}%</span>
                </p>
                <p className="text-muted-foreground mt-1">{anomaly.reason}</p>
              </>
            )}
          </div>
        </div>
      )
    }
    return null
  }

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return '#dc2626'
      case 'high': return '#ea580c'
      case 'medium': return '#f59e0b'
      case 'low': return '#3b82f6'
      default: return '#6b7280'
    }
  }

  const getSeverityBadge = (severity: string) => {
    const colors = {
      critical: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
      high: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200',
      medium: 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200',
      low: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
    }
    return colors[severity as keyof typeof colors] || colors.low
  }

  // Merge anomalies with timeline data for markers
  const timelineWithAnomalies = data?.timeline.map(point => {
    const anomaly = data.anomalies.find(a => a.timestamp === point.timestamp)
    return { ...point, anomaly }
  }) || []

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5" />
            Cost Anomaly Timeline
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load anomaly data. Please try again later.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <AlertTriangle className="h-5 w-5" />
          Cost Anomaly Timeline
        </CardTitle>
        <CardDescription>
          Detect and investigate unusual spending patterns with root cause analysis
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[550px] w-full" />
        ) : data && data.timeline.length > 0 ? (
          <div className="space-y-6">
            {/* Summary Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <Bell className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Total Anomalies</span>
                </div>
                <p className="text-2xl font-bold">{data.total_anomalies}</p>
              </div>

              <div className="p-4 bg-red-50 dark:bg-red-950 rounded-lg border border-red-200 dark:border-red-800">
                <div className="flex items-center gap-2 mb-1">
                  <AlertTriangle className="h-4 w-4 text-red-600" />
                  <span className="text-sm text-muted-foreground">Critical Alerts</span>
                </div>
                <p className="text-2xl font-bold text-red-600">{data.critical_anomalies}</p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <Clock className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Last 24h</span>
                </div>
                <p className="text-2xl font-bold">
                  {data.anomalies.filter(a => {
                    const hoursSince = (Date.now() - new Date(a.timestamp).getTime()) / (1000 * 60 * 60)
                    return hoursSince <= 24
                  }).length}
                </p>
              </div>
            </div>

            {/* Timeline Chart */}
            <ResponsiveContainer width="100%" height={350}>
              <ComposedChart
                data={timelineWithAnomalies}
                margin={{ top: 20, right: 30, left: 20, bottom: 20 }}
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="timestamp"
                  tick={{ fontSize: 11 }}
                  tickFormatter={(value) => {
                    const date = new Date(value)
                    return `${date.getMonth() + 1}/${date.getDate()}`
                  }}
                />
                <YAxis
                  tick={{ fontSize: 11 }}
                  label={{ value: 'Cost ($)', angle: -90, position: 'insideLeft' }}
                  tickFormatter={(value) => `$${value}`}
                />
                <Tooltip content={<CustomTooltip />} />
                <Legend />

                {/* Confidence bands */}
                <Area
                  type="monotone"
                  dataKey="upper_bound"
                  stroke="none"
                  fill="#94a3b8"
                  fillOpacity={0.1}
                  name="Expected Range"
                />
                <Area
                  type="monotone"
                  dataKey="lower_bound"
                  stroke="none"
                  fill="#94a3b8"
                  fillOpacity={0.1}
                />

                {/* Expected cost baseline */}
                <Line
                  type="monotone"
                  dataKey="expected_cost"
                  stroke="#64748b"
                  strokeWidth={2}
                  strokeDasharray="5 5"
                  dot={false}
                  name="Expected Cost"
                />

                {/* Actual cost */}
                <Line
                  type="monotone"
                  dataKey="actual_cost"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  dot={{ r: 3 }}
                  name="Actual Cost"
                />

                {/* Anomaly markers */}
                {data.anomalies.map((anomaly, index) => (
                  <ReferenceDot
                    key={index}
                    x={anomaly.timestamp}
                    y={anomaly.actual_cost}
                    r={8}
                    fill={getSeverityColor(anomaly.severity)}
                    stroke="#fff"
                    strokeWidth={2}
                  />
                ))}
              </ComposedChart>
            </ResponsiveContainer>

            {/* Anomalies Table */}
            {data.anomalies.length > 0 ? (
              <div>
                <h4 className="text-sm font-semibold mb-3">Detected Anomalies</h4>
                <div className="border rounded-lg overflow-hidden">
                  <div className="max-h-64 overflow-y-auto">
                    <table className="w-full text-sm">
                      <thead className="bg-muted sticky top-0">
                        <tr>
                          <th className="text-left p-3 font-semibold">Time</th>
                          <th className="text-right p-3 font-semibold">Actual</th>
                          <th className="text-right p-3 font-semibold">Expected</th>
                          <th className="text-right p-3 font-semibold">Deviation</th>
                          <th className="text-center p-3 font-semibold">Severity</th>
                          <th className="text-left p-3 font-semibold">Reason</th>
                        </tr>
                      </thead>
                      <tbody>
                        {data.anomalies
                          .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
                          .map((anomaly, index) => (
                            <tr key={index} className="border-t hover:bg-muted/50">
                              <td className="p-3 font-mono text-xs">
                                {new Date(anomaly.timestamp).toLocaleString('en-US', {
                                  month: 'short',
                                  day: 'numeric',
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })}
                              </td>
                              <td className="p-3 text-right font-medium">
                                ${anomaly.actual_cost.toFixed(2)}
                              </td>
                              <td className="p-3 text-right text-muted-foreground">
                                ${anomaly.expected_cost.toFixed(2)}
                              </td>
                              <td className="p-3 text-right">
                                <span className={anomaly.deviation_percentage > 0 ? 'text-red-600' : 'text-green-600'}>
                                  {anomaly.deviation_percentage > 0 ? '+' : ''}
                                  {anomaly.deviation_percentage.toFixed(1)}%
                                </span>
                              </td>
                              <td className="p-3 text-center">
                                <span className={`text-xs px-2 py-1 rounded ${getSeverityBadge(anomaly.severity)}`}>
                                  {anomaly.severity}
                                </span>
                              </td>
                              <td className="p-3 text-xs text-muted-foreground max-w-xs truncate">
                                {anomaly.reason}
                                {anomaly.agent_id && <span className="ml-1">({anomaly.agent_id})</span>}
                              </td>
                            </tr>
                          ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            ) : (
              <div className="p-6 bg-green-50 dark:bg-green-950 rounded-lg border border-green-200 dark:border-green-800 text-center">
                <TrendingUp className="h-8 w-8 text-green-600 mx-auto mb-2" />
                <p className="text-sm font-medium text-green-900 dark:text-green-100">
                  No anomalies detected
                </p>
                <p className="text-xs text-green-700 dark:text-green-300 mt-1">
                  Your spending is within expected patterns
                </p>
              </div>
            )}

            {/* Info */}
            <p className="text-xs text-muted-foreground text-center">
              Anomalies are detected using statistical analysis. Critical anomalies exceed expected cost by &gt;50%.
            </p>
          </div>
        ) : (
          <div className="h-[550px] flex items-center justify-center text-muted-foreground">
            Insufficient data for anomaly detection. Need at least 7 days of historical data.
          </div>
        )}
      </CardContent>
    </Card>
  )
}
