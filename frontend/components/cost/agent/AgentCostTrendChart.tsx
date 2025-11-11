'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts'
import { TrendingUp, TrendingDown } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface CostTrendDataPoint {
  timestamp: string
  cost_usd: number
  call_count: number
  avg_cost_per_call: number
}

interface AgentCostTrendChartProps {
  agentId: string
  timeRange: string
}

/**
 * AgentCostTrendChart - Cost trend over time for specific agent
 *
 * Shows daily/hourly cost progression with:
 * - Line chart of total cost
 * - Call volume overlay
 * - Trend indicators
 *
 * PRD Tab 3: Agent Detail Component 1
 */
export function AgentCostTrendChart({ agentId, timeRange }: AgentCostTrendChartProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['agent-cost-trend', agentId, timeRange],
    queryFn: async () => {
      const granularity = timeRange === '1h' || timeRange === '24h' ? 'hourly' : 'daily'
      const response = await apiClient.get(
        `/api/v1/cost/agents/${agentId}/trend?range=${timeRange}&granularity=${granularity}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as CostTrendDataPoint[]
    },
    enabled: !!user?.workspace_id && !!agentId,
    refetchInterval: 60000,
  })

  // Calculate trend
  const trend = data && data.length >= 2
    ? ((data[data.length - 1].cost_usd - data[0].cost_usd) / data[0].cost_usd * 100)
    : 0

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">
            {new Date(label).toLocaleString('en-US', {
              month: 'short',
              day: 'numeric',
              hour: timeRange === '1h' || timeRange === '24h' ? '2-digit' : undefined,
              minute: timeRange === '1h' || timeRange === '24h' ? '2-digit' : undefined
            })}
          </p>
          <div className="space-y-1 text-xs">
            <p>
              <span className="text-muted-foreground">Cost:</span>
              <span className="font-medium ml-2">${data.cost_usd.toFixed(2)}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Calls:</span>
              <span className="font-medium ml-2">{data.call_count.toLocaleString()}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Avg/Call:</span>
              <span className="font-medium ml-2">${data.avg_cost_per_call.toFixed(4)}</span>
            </p>
          </div>
        </div>
      )
    }
    return null
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Cost Trend</CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load cost trend data. Please try again later.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Cost Trend Over Time</CardTitle>
            <CardDescription>
              Daily cost progression and call volume
            </CardDescription>
          </div>
          {data && data.length >= 2 && (
            <div className={`flex items-center gap-2 px-3 py-1 rounded ${
              trend > 0 ? 'bg-red-50 text-red-600 dark:bg-red-950' : 'bg-green-50 text-green-600 dark:bg-green-950'
            }`}>
              {trend > 0 ? (
                <TrendingUp className="h-4 w-4" />
              ) : (
                <TrendingDown className="h-4 w-4" />
              )}
              <span className="text-sm font-semibold">
                {trend > 0 ? '+' : ''}{trend.toFixed(1)}%
              </span>
            </div>
          )}
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[350px] w-full" />
        ) : data && data.length > 0 ? (
          <ResponsiveContainer width="100%" height={350}>
            <AreaChart data={data} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="costGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis
                dataKey="timestamp"
                tick={{ fontSize: 11 }}
                tickFormatter={(value) => {
                  const date = new Date(value)
                  if (timeRange === '1h' || timeRange === '24h') {
                    return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
                  }
                  return `${date.getMonth() + 1}/${date.getDate()}`
                }}
              />
              <YAxis
                yAxisId="left"
                tick={{ fontSize: 11 }}
                tickFormatter={(value) => `$${value.toFixed(2)}`}
                label={{ value: 'Cost ($)', angle: -90, position: 'insideLeft', fontSize: 12 }}
              />
              <YAxis
                yAxisId="right"
                orientation="right"
                tick={{ fontSize: 11 }}
                tickFormatter={(value) => value.toLocaleString()}
                label={{ value: 'Calls', angle: 90, position: 'insideRight', fontSize: 12 }}
              />
              <Tooltip content={<CustomTooltip />} />
              <Legend />
              <Area
                yAxisId="left"
                type="monotone"
                dataKey="cost_usd"
                stroke="#3b82f6"
                strokeWidth={2}
                fill="url(#costGradient)"
                name="Cost"
              />
              <Line
                yAxisId="right"
                type="monotone"
                dataKey="call_count"
                stroke="#10b981"
                strokeWidth={2}
                dot={{ r: 3 }}
                name="Calls"
              />
            </AreaChart>
          </ResponsiveContainer>
        ) : (
          <div className="h-[350px] flex items-center justify-center text-muted-foreground">
            No cost trend data available for this agent
          </div>
        )}
      </CardContent>
    </Card>
  )
}
