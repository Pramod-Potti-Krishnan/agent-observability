'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, Cell } from 'recharts'
import { Zap, TrendingDown, Database } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'

interface TokenFlowData {
  total_input_tokens: number
  total_output_tokens: number
  cached_tokens: number
  cache_hit_rate: number
  cost_breakdown: {
    input_cost: number
    output_cost: number
    cached_cost: number
  }
  savings_from_cache: number
}

/**
 * TokenUsageWaterfall - Token flow and cost waterfall visualization
 *
 * Shows how tokens flow through the system:
 * - Input tokens (user prompts)
 * - Output tokens (AI responses)
 * - Cached tokens (reused from cache)
 *
 * Displays cost at each stage and highlights cache savings.
 *
 * PRD Tab 3: Chart 3.2 - Token Usage Waterfall (P1)
 */
export function TokenUsageWaterfall() {
  const { user } = useAuth()
  const { filters } = useFilters()

  const { data, isLoading, error } = useQuery({
    queryKey: ['token-waterfall', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/token-waterfall?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as TokenFlowData
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000,
  })

  // Prepare waterfall data showing cumulative flow
  const waterfallData = data ? [
    {
      name: 'Input Tokens',
      value: data.total_input_tokens,
      cost: data.cost_breakdown.input_cost,
      color: '#3b82f6', // blue
      type: 'input'
    },
    {
      name: 'Output Tokens',
      value: data.total_output_tokens,
      cost: data.cost_breakdown.output_cost,
      color: '#8b5cf6', // violet
      type: 'output'
    },
    {
      name: 'Cached Tokens',
      value: data.cached_tokens,
      cost: data.cost_breakdown.cached_cost,
      color: '#10b981', // green (savings)
      type: 'cached'
    },
  ] : []

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">{data.name}</p>
          <p className="text-xs text-muted-foreground">
            Tokens: {data.value.toLocaleString()}
          </p>
          <p className="text-sm font-medium text-primary mt-1">
            Cost: ${data.cost.toFixed(4)}
          </p>
          {data.type === 'cached' && (
            <p className="text-xs text-green-600 mt-1">
              💰 Savings opportunity
            </p>
          )}
        </div>
      )
    }
    return null
  }

  const formatNumber = (num: number) => {
    if (num >= 1_000_000) return `${(num / 1_000_000).toFixed(1)}M`
    if (num >= 1_000) return `${(num / 1_000).toFixed(1)}K`
    return num.toString()
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="h-5 w-5" />
            Token Usage Waterfall
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load token usage data. Please try again later.
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
          <Zap className="h-5 w-5" />
          Token Usage Waterfall
        </CardTitle>
        <CardDescription>
          Flow of tokens and associated costs across input, output, and caching
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[400px] w-full" />
        ) : data ? (
          <div className="space-y-4">
            {/* Summary Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 bg-blue-50 dark:bg-blue-950 rounded-lg border border-blue-200 dark:border-blue-800">
                <div className="flex items-center gap-2 mb-1">
                  <Zap className="h-4 w-4 text-blue-600" />
                  <span className="text-sm text-muted-foreground">Total Tokens</span>
                </div>
                <p className="text-2xl font-bold">
                  {formatNumber(data.total_input_tokens + data.total_output_tokens)}
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  Input: {formatNumber(data.total_input_tokens)} | Output: {formatNumber(data.total_output_tokens)}
                </p>
              </div>

              <div className="p-4 bg-green-50 dark:bg-green-950 rounded-lg border border-green-200 dark:border-green-800">
                <div className="flex items-center gap-2 mb-1">
                  <Database className="h-4 w-4 text-green-600" />
                  <span className="text-sm text-muted-foreground">Cache Hit Rate</span>
                </div>
                <p className="text-2xl font-bold text-green-600">
                  {data.cache_hit_rate.toFixed(1)}%
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  {formatNumber(data.cached_tokens)} tokens cached
                </p>
              </div>

              <div className="p-4 bg-amber-50 dark:bg-amber-950 rounded-lg border border-amber-200 dark:border-amber-800">
                <div className="flex items-center gap-2 mb-1">
                  <TrendingDown className="h-4 w-4 text-amber-600" />
                  <span className="text-sm text-muted-foreground">Cache Savings</span>
                </div>
                <p className="text-2xl font-bold text-amber-600">
                  ${data.savings_from_cache.toFixed(2)}
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  Cost avoided via caching
                </p>
              </div>
            </div>

            {/* Waterfall Chart */}
            <ResponsiveContainer width="100%" height={350}>
              <BarChart
                data={waterfallData}
                margin={{ top: 20, right: 30, left: 20, bottom: 20 }}
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="name"
                  tick={{ fontSize: 12 }}
                />
                <YAxis
                  tick={{ fontSize: 12 }}
                  label={{ value: 'Tokens', angle: -90, position: 'insideLeft' }}
                  tickFormatter={formatNumber}
                />
                <Tooltip content={<CustomTooltip />} />
                <Bar dataKey="value" radius={[8, 8, 0, 0]}>
                  {waterfallData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>

            {/* Cost Breakdown */}
            <div className="border-t pt-4">
              <h4 className="text-sm font-semibold mb-3">Cost Breakdown</h4>
              <div className="space-y-2">
                <div className="flex justify-between items-center text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded" style={{ backgroundColor: '#3b82f6' }}></div>
                    <span>Input Token Cost</span>
                  </div>
                  <span className="font-medium">${data.cost_breakdown.input_cost.toFixed(4)}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded" style={{ backgroundColor: '#8b5cf6' }}></div>
                    <span>Output Token Cost</span>
                  </div>
                  <span className="font-medium">${data.cost_breakdown.output_cost.toFixed(4)}</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded" style={{ backgroundColor: '#10b981' }}></div>
                    <span>Cached Token Cost</span>
                  </div>
                  <span className="font-medium">${data.cost_breakdown.cached_cost.toFixed(4)}</span>
                </div>
                <div className="flex justify-between items-center text-sm font-semibold border-t pt-2 mt-2">
                  <span>Total Cost</span>
                  <span className="text-primary">
                    ${(data.cost_breakdown.input_cost + data.cost_breakdown.output_cost + data.cost_breakdown.cached_cost).toFixed(4)}
                  </span>
                </div>
              </div>
            </div>

            <p className="text-xs text-muted-foreground text-center">
              {data.cache_hit_rate > 20 ? (
                <span className="text-green-600">✓ Good cache utilization! Continue optimizing for cost savings.</span>
              ) : data.cache_hit_rate > 10 ? (
                <span className="text-amber-600">⚠ Moderate cache usage. Consider enabling caching for frequently used prompts.</span>
              ) : (
                <span className="text-red-600">⚠ Low cache hit rate. Enable prompt caching to reduce costs significantly.</span>
              )}
            </p>
          </div>
        ) : (
          <div className="h-[400px] flex items-center justify-center text-muted-foreground">
            No token usage data available for the selected time range
          </div>
        )}
      </CardContent>
    </Card>
  )
}
