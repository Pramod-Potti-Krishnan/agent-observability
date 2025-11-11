'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ZAxis, ReferenceLine } from 'recharts'
import { Target, TrendingUp, Award } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'

interface ProviderMetrics {
  provider: string
  avg_cost_per_request: number
  quality_score: number
  total_requests: number
  color: string
}

interface MatrixData {
  providers: ProviderMetrics[]
  optimal_zone: {
    min_quality: number
    max_cost: number
  }
  best_value_provider: string
}

/**
 * ProviderCostPerformanceMatrix - Cost vs Quality scatter plot
 *
 * Compares AI providers across two dimensions:
 * - X-axis: Average cost per request
 * - Y-axis: Quality score (0-100)
 * - Bubble size: Total request volume
 *
 * Identifies "optimal zone" (high quality, low cost) and best value provider.
 *
 * PRD Tab 3: Chart 3.4 - Provider Cost/Performance Matrix (P1)
 */
export function ProviderCostPerformanceMatrix() {
  const { user } = useAuth()
  const { filters } = useFilters()

  const { data, isLoading, error } = useQuery({
    queryKey: ['provider-matrix', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/provider-matrix?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as MatrixData
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 120000, // Refetch every 2 minutes
  })

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">{data.provider}</p>
          <div className="space-y-1 text-xs">
            <p>
              <span className="text-muted-foreground">Cost/Request:</span>
              <span className="font-medium ml-2">${data.avg_cost_per_request.toFixed(4)}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Quality Score:</span>
              <span className="font-medium ml-2">{data.quality_score.toFixed(1)}/100</span>
            </p>
            <p>
              <span className="text-muted-foreground">Total Requests:</span>
              <span className="font-medium ml-2">{data.total_requests.toLocaleString()}</span>
            </p>
          </div>
        </div>
      )
    }
    return null
  }

  const getQuadrantLabel = (cost: number, quality: number) => {
    if (!data?.providers || data.providers.length === 0) return 'Unknown'

    const avgCost = data.providers.reduce((sum, p) => sum + p.avg_cost_per_request, 0) / data.providers.length
    const avgQuality = data.providers.reduce((sum, p) => sum + p.quality_score, 0) / data.providers.length

    if (quality > avgQuality && cost < avgCost) return 'Optimal'
    if (quality > avgQuality && cost > avgCost) return 'Premium'
    if (quality < avgQuality && cost < avgCost) return 'Budget'
    return 'Needs Review'
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target className="h-5 w-5" />
            Provider Cost/Performance Matrix
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load provider metrics. Please try again later.
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
          <Target className="h-5 w-5" />
          Provider Cost/Performance Matrix
        </CardTitle>
        <CardDescription>
          Compare AI providers by cost efficiency and quality scores
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[450px] w-full" />
        ) : data && data.providers.length > 0 ? (
          <div className="space-y-4">
            {/* Best Value Provider */}
            {data.best_value_provider && (
              <div className="p-4 bg-green-50 dark:bg-green-950 rounded-lg border border-green-200 dark:border-green-800">
                <div className="flex items-center gap-2 mb-1">
                  <Award className="h-4 w-4 text-green-600" />
                  <span className="text-sm font-semibold text-green-900 dark:text-green-100">
                    Best Value Provider
                  </span>
                </div>
                <p className="text-lg font-bold text-green-700 dark:text-green-300">
                  {data.best_value_provider}
                </p>
                <p className="text-xs text-green-600 dark:text-green-400 mt-1">
                  Optimal balance of cost and quality
                </p>
              </div>
            )}

            {/* Scatter Plot */}
            <ResponsiveContainer width="100%" height={400}>
              <ScatterChart margin={{ top: 20, right: 30, left: 20, bottom: 20 }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  type="number"
                  dataKey="avg_cost_per_request"
                  name="Cost per Request"
                  tick={{ fontSize: 11 }}
                  label={{ value: 'Cost per Request ($)', position: 'bottom', fontSize: 12 }}
                  tickFormatter={(value) => `$${value.toFixed(4)}`}
                />
                <YAxis
                  type="number"
                  dataKey="quality_score"
                  name="Quality Score"
                  tick={{ fontSize: 11 }}
                  label={{ value: 'Quality Score', angle: -90, position: 'insideLeft', fontSize: 12 }}
                  domain={[0, 100]}
                />
                <ZAxis
                  type="number"
                  dataKey="total_requests"
                  range={[100, 1000]}
                  name="Requests"
                />
                <Tooltip content={<CustomTooltip />} cursor={{ strokeDasharray: '3 3' }} />
                <Legend
                  wrapperStyle={{ fontSize: '12px' }}
                  formatter={(value) => value}
                />

                {/* Reference lines for optimal zone */}
                {data.optimal_zone && (
                  <>
                    <ReferenceLine
                      y={data.optimal_zone.min_quality}
                      stroke="#10b981"
                      strokeDasharray="5 5"
                      label={{ value: 'Min Quality', position: 'right', fontSize: 10 }}
                    />
                    <ReferenceLine
                      x={data.optimal_zone.max_cost}
                      stroke="#10b981"
                      strokeDasharray="5 5"
                      label={{ value: 'Max Cost', position: 'top', fontSize: 10 }}
                    />
                  </>
                )}

                <Scatter
                  name="Providers"
                  data={data.providers}
                  fill="#8884d8"
                >
                  {data.providers.map((entry, index) => (
                    <circle
                      key={`dot-${index}`}
                      cx={0}
                      cy={0}
                      r={Math.sqrt(entry.total_requests / 10)}
                      fill={entry.color || '#8884d8'}
                    />
                  ))}
                </Scatter>
              </ScatterChart>
            </ResponsiveContainer>

            {/* Provider Table */}
            <div className="border rounded-lg overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-muted">
                  <tr>
                    <th className="text-left p-3 font-semibold">Provider</th>
                    <th className="text-right p-3 font-semibold">Cost/Request</th>
                    <th className="text-right p-3 font-semibold">Quality</th>
                    <th className="text-right p-3 font-semibold">Requests</th>
                    <th className="text-center p-3 font-semibold">Zone</th>
                  </tr>
                </thead>
                <tbody>
                  {data.providers.map((provider, index) => {
                    const zone = getQuadrantLabel(provider.avg_cost_per_request, provider.quality_score)
                    return (
                      <tr key={index} className="border-t hover:bg-muted/50">
                        <td className="p-3 font-medium">{provider.provider}</td>
                        <td className="p-3 text-right">${provider.avg_cost_per_request.toFixed(4)}</td>
                        <td className="p-3 text-right">{provider.quality_score.toFixed(1)}/100</td>
                        <td className="p-3 text-right">{provider.total_requests.toLocaleString()}</td>
                        <td className="p-3 text-center">
                          <span className={`text-xs px-2 py-1 rounded ${
                            zone === 'Optimal' ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' :
                            zone === 'Premium' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' :
                            zone === 'Budget' ? 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200' :
                            'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
                          }`}>
                            {zone}
                          </span>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>

            {/* Legend */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded bg-green-500"></div>
                <span>Optimal (High Quality, Low Cost)</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded bg-blue-500"></div>
                <span>Premium (High Quality, High Cost)</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded bg-amber-500"></div>
                <span>Budget (Low Quality, Low Cost)</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded bg-red-500"></div>
                <span>Needs Review (Low Quality, High Cost)</span>
              </div>
            </div>

            <p className="text-xs text-muted-foreground text-center">
              Bubble size represents total request volume. Target the green optimal zone for best value.
            </p>
          </div>
        ) : (
          <div className="h-[450px] flex items-center justify-center text-muted-foreground">
            No provider data available for the selected time range
          </div>
        )}
      </CardContent>
    </Card>
  )
}
