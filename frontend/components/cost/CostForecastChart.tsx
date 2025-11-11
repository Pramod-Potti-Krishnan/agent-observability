'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ReferenceLine,
  Area,
  ComposedChart
} from 'recharts'
import { TrendingUp, Calendar, AlertTriangle } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'

interface ForecastDataPoint {
  date: string
  actual_cost?: number
  forecasted_cost: number
  lower_bound: number
  upper_bound: number
  is_forecast: boolean
}

interface CostForecastData {
  historical: ForecastDataPoint[]
  forecast: ForecastDataPoint[]
  total_forecasted_cost: number
  trend: 'increasing' | 'decreasing' | 'stable'
  confidence_level: number
}

/**
 * CostForecastChart - 30-day predictive cost modeling
 *
 * Shows historical costs and forecasts future spending:
 * - Historical actual costs (solid line)
 * - Forecasted costs (dashed line)
 * - Confidence intervals (shaded area)
 * - Trend analysis and alerts
 *
 * Uses time-series forecasting to predict future costs.
 *
 * PRD Tab 3: Chart 3.3 - Cost Forecast Chart (P1)
 */
export function CostForecastChart() {
  const { user } = useAuth()
  const { filters } = useFilters()

  const { data, isLoading, error } = useQuery({
    queryKey: ['cost-forecast', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/forecast?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as CostForecastData
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 300000, // Refetch every 5 minutes
  })

  const allData = data ? [...data.historical, ...data.forecast] : []

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const dataPoint = payload[0].payload
      const isForecast = dataPoint.is_forecast

      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">
            {new Date(label).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
          </p>
          {isForecast ? (
            <>
              <p className="text-xs text-muted-foreground mb-1">Forecasted</p>
              <p className="text-sm font-medium text-primary">
                ${dataPoint.forecasted_cost.toFixed(2)}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                Range: ${dataPoint.lower_bound.toFixed(2)} - ${dataPoint.upper_bound.toFixed(2)}
              </p>
            </>
          ) : (
            <>
              <p className="text-xs text-muted-foreground mb-1">Actual</p>
              <p className="text-sm font-medium text-primary">
                ${dataPoint.actual_cost?.toFixed(2) || '0.00'}
              </p>
            </>
          )}
        </div>
      )
    }
    return null
  }

  const getTrendIcon = () => {
    if (!data) return null
    if (data.trend === 'increasing') return <TrendingUp className="h-4 w-4 text-red-500" />
    if (data.trend === 'decreasing') return <TrendingUp className="h-4 w-4 text-green-500 rotate-180" />
    return <div className="h-4 w-4" />
  }

  const getTrendColor = () => {
    if (!data) return 'text-muted-foreground'
    if (data.trend === 'increasing') return 'text-red-600'
    if (data.trend === 'decreasing') return 'text-green-600'
    return 'text-gray-600'
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Cost Forecast (30 Days)
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load cost forecast. Please try again later.
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
          <Calendar className="h-5 w-5" />
          Cost Forecast (30 Days)
        </CardTitle>
        <CardDescription>
          Predictive modeling of future costs based on historical trends
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[450px] w-full" />
        ) : data && allData.length > 0 ? (
          <div className="space-y-4">
            {/* Summary Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <Calendar className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">30-Day Forecast</span>
                </div>
                <p className="text-2xl font-bold">
                  ${data.total_forecasted_cost.toFixed(2)}
                </p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  {getTrendIcon()}
                  <span className="text-sm text-muted-foreground">Trend</span>
                </div>
                <p className={`text-lg font-semibold capitalize ${getTrendColor()}`}>
                  {data.trend}
                </p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <AlertTriangle className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Confidence</span>
                </div>
                <p className="text-2xl font-bold">
                  {data.confidence_level.toFixed(0)}%
                </p>
              </div>
            </div>

            {/* Forecast Chart */}
            <ResponsiveContainer width="100%" height={350}>
              <ComposedChart
                data={allData}
                margin={{ top: 20, right: 30, left: 20, bottom: 20 }}
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="date"
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

                {/* Confidence interval area for forecast */}
                <Area
                  type="monotone"
                  dataKey="upper_bound"
                  stroke="none"
                  fill="#3b82f6"
                  fillOpacity={0.1}
                  name="Confidence Interval"
                />
                <Area
                  type="monotone"
                  dataKey="lower_bound"
                  stroke="none"
                  fill="#3b82f6"
                  fillOpacity={0.1}
                />

                {/* Actual costs (historical) */}
                <Line
                  type="monotone"
                  dataKey="actual_cost"
                  stroke="#8b5cf6"
                  strokeWidth={2}
                  dot={{ r: 3 }}
                  name="Actual Cost"
                  connectNulls
                />

                {/* Forecasted costs */}
                <Line
                  type="monotone"
                  dataKey="forecasted_cost"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  strokeDasharray="5 5"
                  dot={{ r: 3, fill: '#3b82f6' }}
                  name="Forecasted Cost"
                />

                {/* Reference line at today */}
                <ReferenceLine
                  x={new Date().toISOString().split('T')[0]}
                  stroke="#64748b"
                  strokeDasharray="3 3"
                  label={{ value: 'Today', position: 'top', fontSize: 11 }}
                />
              </ComposedChart>
            </ResponsiveContainer>

            {/* Insights */}
            {data.trend === 'increasing' && (
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  <strong>Cost Increasing:</strong> Your costs are trending upward.
                  Consider reviewing agent usage patterns and implementing optimization strategies.
                </AlertDescription>
              </Alert>
            )}

            {data.trend === 'decreasing' && (
              <Alert className="border-green-200 bg-green-50 dark:bg-green-950">
                <TrendingUp className="h-4 w-4 text-green-600 rotate-180" />
                <AlertDescription className="text-green-800 dark:text-green-200">
                  <strong>Cost Decreasing:</strong> Great! Your optimization efforts are paying off.
                  Continue monitoring to maintain this trend.
                </AlertDescription>
              </Alert>
            )}

            <p className="text-xs text-muted-foreground text-center">
              Forecast based on {data.historical.length} days of historical data.
              Shaded area represents {data.confidence_level}% confidence interval.
            </p>
          </div>
        ) : (
          <div className="h-[450px] flex items-center justify-center text-muted-foreground">
            Insufficient historical data for cost forecasting. Need at least 7 days of data.
          </div>
        )}
      </CardContent>
    </Card>
  )
}
