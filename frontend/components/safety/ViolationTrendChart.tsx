import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

interface DataPoint {
  date: string
  critical: number
  high: number
  medium: number
}

interface ViolationTrendChartProps {
  data: DataPoint[]
  loading?: boolean
}

export function ViolationTrendChart({ data, loading = false }: ViolationTrendChartProps) {
  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Violations Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[300px] w-full" />
        </CardContent>
      </Card>
    )
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Violations Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center text-muted-foreground">
            No violations detected - your agents are safe!
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Violations Over Time</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis
              dataKey="date"
              tickFormatter={(value) => {
                const date = new Date(value)
                return date.toLocaleDateString([], {
                  month: 'short',
                  day: 'numeric'
                })
              }}
            />
            <YAxis />
            <Tooltip
              labelFormatter={(value) => new Date(value).toLocaleDateString()}
              formatter={(value: number, name: string) => {
                const labels: Record<string, string> = {
                  critical: 'Critical',
                  high: 'High',
                  medium: 'Medium'
                }
                return [value.toLocaleString(), labels[name] || name]
              }}
            />
            <Legend
              formatter={(value) => {
                const labels: Record<string, string> = {
                  critical: 'Critical',
                  high: 'High',
                  medium: 'Medium'
                }
                return labels[value] || value
              }}
            />
            <Line
              type="monotone"
              dataKey="critical"
              stroke="#ef4444"
              strokeWidth={2}
              name="critical"
              dot={{ fill: '#ef4444' }}
            />
            <Line
              type="monotone"
              dataKey="high"
              stroke="#f97316"
              strokeWidth={2}
              name="high"
              dot={{ fill: '#f97316' }}
            />
            <Line
              type="monotone"
              dataKey="medium"
              stroke="#eab308"
              strokeWidth={2}
              name="medium"
              dot={{ fill: '#eab308' }}
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
