'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts'
import { Zap, TrendingUp, TrendingDown } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface TokenEfficiencyMetrics {
  avg_tokens_per_call: number
  avg_input_tokens: number
  avg_output_tokens: number
  cache_hit_rate: number
  cost_per_1k_tokens: number
  efficiency_score: number
  trend_data: Array<{
    timestamp: string
    tokens_per_call: number
    cost_per_token: number
  }>
}

interface AgentTokenEfficiencyProps {
  agentId: string
  timeRange: string
}

/**
 * AgentTokenEfficiency - Token usage efficiency metrics
 *
 * Analyzes token consumption patterns:
 * - Tokens per call trend
 * - Input/output token ratio
 * - Cost per token
 * - Cache utilization
 * - Efficiency score
 *
 * PRD Tab 3: Agent Detail Component 4
 */
export function AgentTokenEfficiency({ agentId, timeRange }: AgentTokenEfficiencyProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['agent-token-efficiency', agentId, timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/agents/${agentId}/token-efficiency?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as TokenEfficiencyMetrics
    },
    enabled: !!user?.workspace_id && !!agentId,
    refetchInterval: 60000,
  })

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">
            {new Date(label).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
          </p>
          <div className="space-y-1 text-xs">
            <p>
              <span className="text-muted-foreground">Tokens/Call:</span>
              <span className="font-medium ml-2">{payload[0].value.toLocaleString()}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Cost/Token:</span>
              <span className="font-medium ml-2">${payload[1].value.toFixed(6)}</span>
            </p>
          </div>
        </div>
      )
    }
    return null
  }

  const getEfficiencyRating = (score: number) => {
    if (score >= 80) return { label: 'Excellent', color: 'text-green-600', bgColor: 'bg-green-50 dark:bg-green-950', icon: TrendingUp }
    if (score >= 60) return { label: 'Good', color: 'text-blue-600', bgColor: 'bg-blue-50 dark:bg-blue-950', icon: TrendingUp }
    if (score >= 40) return { label: 'Fair', color: 'text-amber-600', bgColor: 'bg-amber-50 dark:bg-amber-950', icon: TrendingDown }
    return { label: 'Needs Improvement', color: 'text-red-600', bgColor: 'bg-red-50 dark:bg-red-950', icon: TrendingDown }
  }

  const rating = data ? getEfficiencyRating(data.efficiency_score) : null
  const Icon = rating?.icon

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="h-5 w-5" />
            Token Efficiency
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load token efficiency data. Please try again later.
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
          Token Efficiency
        </CardTitle>
        <CardDescription>
          Token consumption patterns and cost optimization
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[400px] w-full" />
        ) : data ? (
          <div className="space-y-4">
            {/* Efficiency Score */}
            {rating && Icon && (
              <div className={`p-4 rounded-lg ${rating.bgColor}`}>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Efficiency Score</p>
                    <p className={`text-3xl font-bold ${rating.color}`}>
                      {data.efficiency_score.toFixed(0)}/100
                    </p>
                    <p className={`text-sm font-medium mt-1 ${rating.color}`}>
                      {rating.label}
                    </p>
                  </div>
                  <Icon className={`h-10 w-10 ${rating.color}`} />
                </div>
              </div>
            )}

            {/* Key Metrics */}
            <div className="grid grid-cols-2 gap-3">
              <div className="p-3 bg-muted rounded-lg">
                <p className="text-xs text-muted-foreground mb-1">Avg Tokens/Call</p>
                <p className="text-lg font-bold">{data.avg_tokens_per_call.toLocaleString()}</p>
              </div>

              <div className="p-3 bg-muted rounded-lg">
                <p className="text-xs text-muted-foreground mb-1">Cost per 1K Tokens</p>
                <p className="text-lg font-bold">${data.cost_per_1k_tokens.toFixed(4)}</p>
              </div>

              <div className="p-3 bg-muted rounded-lg">
                <p className="text-xs text-muted-foreground mb-1">Cache Hit Rate</p>
                <p className="text-lg font-bold text-green-600">{data.cache_hit_rate.toFixed(1)}%</p>
              </div>

              <div className="p-3 bg-muted rounded-lg">
                <p className="text-xs text-muted-foreground mb-1">Input/Output Ratio</p>
                <p className="text-lg font-bold">
                  {(data.avg_input_tokens / Math.max(data.avg_output_tokens, 1)).toFixed(2)}:1
                </p>
              </div>
            </div>

            {/* Token Breakdown */}
            <div className="border rounded-lg p-4">
              <h4 className="text-sm font-semibold mb-3">Token Breakdown</h4>
              <div className="space-y-3">
                <div>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-muted-foreground">Input Tokens</span>
                    <span className="font-medium">{data.avg_input_tokens.toLocaleString()}</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-blue-600 h-2 rounded-full"
                      style={{
                        width: `${(data.avg_input_tokens / data.avg_tokens_per_call) * 100}%`
                      }}
                    />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-muted-foreground">Output Tokens</span>
                    <span className="font-medium">{data.avg_output_tokens.toLocaleString()}</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-purple-600 h-2 rounded-full"
                      style={{
                        width: `${(data.avg_output_tokens / data.avg_tokens_per_call) * 100}%`
                      }}
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Trend Chart */}
            {data.trend_data && data.trend_data.length > 0 && (
              <div>
                <h4 className="text-sm font-semibold mb-3">Efficiency Trend</h4>
                <ResponsiveContainer width="100%" height={200}>
                  <LineChart data={data.trend_data}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis
                      dataKey="timestamp"
                      tick={{ fontSize: 10 }}
                      tickFormatter={(value) => {
                        const date = new Date(value)
                        return `${date.getMonth() + 1}/${date.getDate()}`
                      }}
                    />
                    <YAxis
                      yAxisId="left"
                      tick={{ fontSize: 10 }}
                      tickFormatter={(value) => value.toLocaleString()}
                    />
                    <YAxis
                      yAxisId="right"
                      orientation="right"
                      tick={{ fontSize: 10 }}
                      tickFormatter={(value) => `$${value.toFixed(5)}`}
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ fontSize: '11px' }} />
                    <Line
                      yAxisId="left"
                      type="monotone"
                      dataKey="tokens_per_call"
                      stroke="#3b82f6"
                      strokeWidth={2}
                      dot={{ r: 2 }}
                      name="Tokens/Call"
                    />
                    <Line
                      yAxisId="right"
                      type="monotone"
                      dataKey="cost_per_token"
                      stroke="#10b981"
                      strokeWidth={2}
                      dot={{ r: 2 }}
                      name="Cost/Token"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}

            {/* Optimization Tips */}
            <div className="bg-blue-50 dark:bg-blue-950 rounded-lg p-3 border border-blue-200 dark:border-blue-800">
              <h4 className="text-sm font-semibold text-blue-900 dark:text-blue-100 mb-2">
                💡 Optimization Tips
              </h4>
              <ul className="text-xs text-blue-800 dark:text-blue-200 space-y-1 ml-4 list-disc">
                {data.cache_hit_rate < 30 && (
                  <li>Enable prompt caching to reduce token costs by up to 90%</li>
                )}
                {data.avg_output_tokens > data.avg_input_tokens * 2 && (
                  <li>Output tokens are high. Consider more specific prompts to reduce verbosity</li>
                )}
                {data.efficiency_score < 60 && (
                  <li>Review model selection - consider using more cost-effective models</li>
                )}
              </ul>
            </div>
          </div>
        ) : (
          <div className="h-[400px] flex items-center justify-center text-muted-foreground">
            No token efficiency data available
          </div>
        )}
      </CardContent>
    </Card>
  )
}
