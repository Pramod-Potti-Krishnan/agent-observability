'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, PieChart, Pie, Cell, Legend, Tooltip } from 'recharts'
import { Database, DollarSign, Percent, TrendingUp } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'

interface CacheMetrics {
  total_requests: number
  cache_hits: number
  cache_misses: number
  cache_hit_rate: number
  cost_with_cache: number
  cost_without_cache: number
  total_savings: number
  roi_percentage: number
  avg_response_time_cached_ms: number
  avg_response_time_uncached_ms: number
}

/**
 * CachingROICalculator - Cache performance and ROI analysis
 *
 * Displays comprehensive caching metrics:
 * - Cache hit/miss rates
 * - Cost savings from caching
 * - ROI calculation
 * - Performance improvements
 *
 * Helps justify investment in caching infrastructure.
 *
 * PRD Tab 3: Chart 3.5 - Caching ROI Calculator (P1)
 */
export function CachingROICalculator() {
  const { user } = useAuth()
  const { filters } = useFilters()

  const { data, isLoading, error } = useQuery({
    queryKey: ['caching-roi', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/caching-roi?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as CacheMetrics
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 120000,
  })

  const pieData = data ? [
    { name: 'Cache Hits', value: data.cache_hits, color: '#10b981' },
    { name: 'Cache Misses', value: data.cache_misses, color: '#ef4444' },
  ] : []

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const dataPoint = payload[0]
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-1">{dataPoint.name}</p>
          <p className="text-sm">
            {dataPoint.value.toLocaleString()} requests
          </p>
          <p className="text-xs text-muted-foreground">
            {((dataPoint.value / (data?.total_requests || 1)) * 100).toFixed(1)}%
          </p>
        </div>
      )
    }
    return null
  }

  const getROIRating = (roi: number) => {
    if (roi >= 300) return { label: 'Excellent', color: 'text-green-600', bgColor: 'bg-green-50 dark:bg-green-950' }
    if (roi >= 200) return { label: 'Very Good', color: 'text-blue-600', bgColor: 'bg-blue-50 dark:bg-blue-950' }
    if (roi >= 100) return { label: 'Good', color: 'text-amber-600', bgColor: 'bg-amber-50 dark:bg-amber-950' }
    return { label: 'Needs Improvement', color: 'text-red-600', bgColor: 'bg-red-50 dark:bg-red-950' }
  }

  const rating = data ? getROIRating(data.roi_percentage) : null

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="h-5 w-5" />
            Caching ROI Calculator
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load caching metrics. Please try again later.
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
          <Database className="h-5 w-5" />
          Caching ROI Calculator
        </CardTitle>
        <CardDescription>
          Analyze cache performance and cost savings from prompt caching
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[500px] w-full" />
        ) : data && data.total_requests > 0 ? (
          <div className="space-y-6">
            {/* ROI Summary */}
            <div className={`p-6 rounded-lg ${rating?.bgColor}`}>
              <div className="flex items-center justify-between mb-4">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">Return on Investment</p>
                  <p className={`text-4xl font-bold ${rating?.color}`}>
                    {data.roi_percentage.toFixed(0)}%
                  </p>
                  <p className={`text-sm font-medium mt-1 ${rating?.color}`}>
                    {rating?.label}
                  </p>
                </div>
                <TrendingUp className={`h-12 w-12 ${rating?.color}`} />
              </div>
              <p className="text-sm text-muted-foreground">
                For every $1 spent on caching infrastructure, you save ${(data.roi_percentage / 100).toFixed(2)} in API costs
              </p>
            </div>

            {/* Key Metrics Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <Percent className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Cache Hit Rate</span>
                </div>
                <p className="text-2xl font-bold text-green-600">
                  {data.cache_hit_rate.toFixed(1)}%
                </p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <DollarSign className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Total Savings</span>
                </div>
                <p className="text-2xl font-bold text-green-600">
                  ${data.total_savings.toFixed(2)}
                </p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <Database className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Cache Hits</span>
                </div>
                <p className="text-2xl font-bold">
                  {data.cache_hits.toLocaleString()}
                </p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <TrendingUp className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Speed Improvement</span>
                </div>
                <p className="text-2xl font-bold text-blue-600">
                  {((1 - data.avg_response_time_cached_ms / data.avg_response_time_uncached_ms) * 100).toFixed(0)}%
                </p>
              </div>
            </div>

            {/* Cache Hit/Miss Pie Chart */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4 className="text-sm font-semibold mb-3">Cache Hit/Miss Distribution</h4>
                <ResponsiveContainer width="100%" height={250}>
                  <PieChart>
                    <Pie
                      data={pieData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {pieData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                  </PieChart>
                </ResponsiveContainer>
              </div>

              {/* Cost Comparison */}
              <div>
                <h4 className="text-sm font-semibold mb-3">Cost Impact Analysis</h4>
                <div className="space-y-4 mt-6">
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">Cost with Caching</span>
                      <span className="text-lg font-bold text-green-600">
                        ${data.cost_with_cache.toFixed(2)}
                      </span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div
                        className="bg-green-600 h-2 rounded-full"
                        style={{ width: `${(data.cost_with_cache / data.cost_without_cache) * 100}%` }}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">Cost without Caching</span>
                      <span className="text-lg font-bold text-red-600">
                        ${data.cost_without_cache.toFixed(2)}
                      </span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div className="bg-red-600 h-2 rounded-full" style={{ width: '100%' }} />
                    </div>
                  </div>

                  <div className="pt-4 border-t">
                    <div className="flex justify-between items-center">
                      <span className="text-sm font-semibold">Total Savings</span>
                      <span className="text-xl font-bold text-green-600">
                        ${data.total_savings.toFixed(2)}
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">
                      {((data.total_savings / data.cost_without_cache) * 100).toFixed(1)}% cost reduction
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Performance Comparison */}
            <div className="border-t pt-4">
              <h4 className="text-sm font-semibold mb-3">Performance Impact</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-3 bg-green-50 dark:bg-green-950 rounded border border-green-200 dark:border-green-800">
                  <p className="text-xs text-muted-foreground mb-1">Avg Response Time (Cached)</p>
                  <p className="text-2xl font-bold text-green-700 dark:text-green-300">
                    {data.avg_response_time_cached_ms.toFixed(0)}ms
                  </p>
                </div>
                <div className="p-3 bg-red-50 dark:bg-red-950 rounded border border-red-200 dark:border-red-800">
                  <p className="text-xs text-muted-foreground mb-1">Avg Response Time (Uncached)</p>
                  <p className="text-2xl font-bold text-red-700 dark:text-red-300">
                    {data.avg_response_time_uncached_ms.toFixed(0)}ms
                  </p>
                </div>
              </div>
            </div>

            {/* Recommendations */}
            <div className="bg-blue-50 dark:bg-blue-950 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
              <h4 className="text-sm font-semibold text-blue-900 dark:text-blue-100 mb-2">
                💡 Optimization Recommendations
              </h4>
              <ul className="text-sm text-blue-800 dark:text-blue-200 space-y-1 ml-4 list-disc">
                {data.cache_hit_rate < 30 && (
                  <li>Cache hit rate is low. Enable caching for frequently used prompts.</li>
                )}
                {data.cache_hit_rate >= 30 && data.cache_hit_rate < 60 && (
                  <li>Good cache utilization. Identify additional cacheable patterns.</li>
                )}
                {data.cache_hit_rate >= 60 && (
                  <li>Excellent cache performance! Continue monitoring and optimizing.</li>
                )}
                <li>Potential annual savings: ${(data.total_savings * 365 / (filters.range === '7d' ? 7 : filters.range === '30d' ? 30 : 1)).toFixed(2)}</li>
              </ul>
            </div>
          </div>
        ) : (
          <div className="h-[500px] flex items-center justify-center text-muted-foreground">
            No caching data available for the selected time range
          </div>
        )}
      </CardContent>
    </Card>
  )
}
