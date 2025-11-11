'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ReferenceLine, Cell } from 'recharts'
import { Users, TrendingUp, TrendingDown } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface PeerComparison {
  agent_id: string
  agent_name: string
  total_cost_usd: number
  avg_cost_per_call_usd: number
  total_calls: number
  is_current_agent: boolean
}

interface ComparisonData {
  current_agent: PeerComparison
  peers: PeerComparison[]
  department_average: number
  workspace_average: number
  percentile_rank: number
}

interface AgentCostComparisonProps {
  agentId: string
  timeRange: string
}

/**
 * AgentCostComparison - Compare agent with peers
 *
 * Benchmarks agent cost against:
 * - Similar agents in same department
 * - Department average
 * - Workspace average
 * - Percentile ranking
 *
 * PRD Tab 3: Agent Detail Component 3
 */
export function AgentCostComparison({ agentId, timeRange }: AgentCostComparisonProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['agent-cost-comparison', agentId, timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/agents/${agentId}/comparison?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as ComparisonData
    },
    enabled: !!user?.workspace_id && !!agentId,
    refetchInterval: 60000,
  })

  const chartData = data ? [
    ...data.peers.map(peer => ({
      name: peer.agent_name,
      cost: peer.total_cost_usd,
      isCurrent: peer.is_current_agent,
    })),
  ].sort((a, b) => b.cost - a.cost) : []

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">{data.name}</p>
          <p className="text-xs">
            <span className="text-muted-foreground">Total Cost:</span>
            <span className="font-medium ml-2">${data.cost.toFixed(2)}</span>
          </p>
          {data.isCurrent && (
            <p className="text-xs text-primary mt-1 font-medium">Current Agent</p>
          )}
        </div>
      )
    }
    return null
  }

  const getPercentileRating = (percentile: number) => {
    if (percentile >= 75) return { label: 'Top 25%', color: 'text-green-600', bgColor: 'bg-green-50 dark:bg-green-950' }
    if (percentile >= 50) return { label: 'Above Average', color: 'text-blue-600', bgColor: 'bg-blue-50 dark:bg-blue-950' }
    if (percentile >= 25) return { label: 'Below Average', color: 'text-amber-600', bgColor: 'bg-amber-50 dark:bg-amber-950' }
    return { label: 'Bottom 25%', color: 'text-red-600', bgColor: 'bg-red-50 dark:bg-red-950' }
  }

  const rating = data ? getPercentileRating(data.percentile_rank) : null

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Cost Comparison
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load comparison data. Please try again later.
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
          <Users className="h-5 w-5" />
          Cost Comparison
        </CardTitle>
        <CardDescription>
          Benchmark against similar agents in your department
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[400px] w-full" />
        ) : data && chartData.length > 0 ? (
          <div className="space-y-4">
            {/* Percentile Ranking */}
            {rating && (
              <div className={`p-4 rounded-lg ${rating.bgColor}`}>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-muted-foreground mb-1">Cost Efficiency Ranking</p>
                    <p className={`text-2xl font-bold ${rating.color}`}>
                      {rating.label}
                    </p>
                    <p className="text-xs text-muted-foreground mt-1">
                      {data.percentile_rank.toFixed(0)}th percentile (lower cost is better)
                    </p>
                  </div>
                  {data.percentile_rank >= 50 ? (
                    <TrendingDown className={`h-10 w-10 ${rating.color}`} />
                  ) : (
                    <TrendingUp className={`h-10 w-10 ${rating.color}`} />
                  )}
                </div>
              </div>
            )}

            {/* Comparison Bar Chart */}
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={chartData} layout="horizontal">
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="name"
                  tick={{ fontSize: 10 }}
                  angle={-45}
                  textAnchor="end"
                  height={80}
                />
                <YAxis
                  tick={{ fontSize: 11 }}
                  tickFormatter={(value) => `$${value.toFixed(0)}`}
                />
                <Tooltip content={<CustomTooltip />} />
                <ReferenceLine
                  y={data.department_average}
                  stroke="#f59e0b"
                  strokeDasharray="5 5"
                  label={{ value: 'Dept Avg', position: 'right', fontSize: 10 }}
                />
                <Bar
                  dataKey="cost"
                  fill="#3b82f6"
                  radius={[4, 4, 0, 0]}
                >
                  {chartData.map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={entry.isCurrent ? '#10b981' : '#3b82f6'}
                    />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>

            {/* Benchmarks */}
            <div className="grid grid-cols-2 gap-3">
              <div className="p-3 bg-muted rounded-lg">
                <p className="text-xs text-muted-foreground mb-1">Department Average</p>
                <p className="text-lg font-bold">${data.department_average.toFixed(2)}</p>
                <p className={`text-xs mt-1 ${
                  data.current_agent.total_cost_usd < data.department_average
                    ? 'text-green-600'
                    : 'text-red-600'
                }`}>
                  {data.current_agent.total_cost_usd < data.department_average ? (
                    <>-{((1 - data.current_agent.total_cost_usd / data.department_average) * 100).toFixed(1)}% below</>
                  ) : (
                    <>+{((data.current_agent.total_cost_usd / data.department_average - 1) * 100).toFixed(1)}% above</>
                  )}
                </p>
              </div>

              <div className="p-3 bg-muted rounded-lg">
                <p className="text-xs text-muted-foreground mb-1">Workspace Average</p>
                <p className="text-lg font-bold">${data.workspace_average.toFixed(2)}</p>
                <p className={`text-xs mt-1 ${
                  data.current_agent.total_cost_usd < data.workspace_average
                    ? 'text-green-600'
                    : 'text-red-600'
                }`}>
                  {data.current_agent.total_cost_usd < data.workspace_average ? (
                    <>-{((1 - data.current_agent.total_cost_usd / data.workspace_average) * 100).toFixed(1)}% below</>
                  ) : (
                    <>+{((data.current_agent.total_cost_usd / data.workspace_average - 1) * 100).toFixed(1)}% above</>
                  )}
                </p>
              </div>
            </div>
          </div>
        ) : (
          <div className="h-[400px] flex items-center justify-center text-muted-foreground">
            No comparison data available
          </div>
        )}
      </CardContent>
    </Card>
  )
}
