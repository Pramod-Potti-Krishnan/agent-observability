import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { Skeleton } from '@/components/ui/skeleton'

interface DataPoint {
  date: string
  cost_savings: number
  support_tickets_reduced: number
  csat_improvement: number
}

interface ImpactTimelineChartProps {
  data: DataPoint[]
  loading?: boolean
}

export function ImpactTimelineChart({ data, loading = false }: ImpactTimelineChartProps) {
  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Impact Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[350px] w-full" />
        </CardContent>
      </Card>
    )
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Impact Over Time</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[350px] flex items-center justify-center text-muted-foreground">
            No timeline data available
          </div>
        </CardContent>
      </Card>
    )
  }

  // Normalize data to 0-100 scale for better visualization
  const normalizedData = data.map((point) => {
    // Find max values for normalization
    const maxSavings = Math.max(...data.map(d => d.cost_savings))
    const maxTickets = Math.max(...data.map(d => d.support_tickets_reduced))
    const maxCSAT = Math.max(...data.map(d => d.csat_improvement))

    return {
      date: point.date,
      'Cost Savings': maxSavings > 0 ? (point.cost_savings / maxSavings) * 100 : 0,
      'Support Tickets': maxTickets > 0 ? (point.support_tickets_reduced / maxTickets) * 100 : 0,
      'CSAT Improvement': maxCSAT > 0 ? (point.csat_improvement / maxCSAT) * 100 : 0,
      // Keep original values for tooltip
      originalSavings: point.cost_savings,
      originalTickets: point.support_tickets_reduced,
      originalCSAT: point.csat_improvement
    }
  })

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const date = new Date(label).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      })

      return (
        <div className="bg-popover text-popover-foreground p-3 rounded-lg shadow-lg border">
          <p className="font-semibold mb-2">{date}</p>
          {payload.map((entry: any, index: number) => {
            let originalValue = 0
            let displayValue = ''

            if (entry.name === 'Cost Savings') {
              originalValue = entry.payload.originalSavings
              displayValue = `$${originalValue.toLocaleString()}`
            } else if (entry.name === 'Support Tickets') {
              originalValue = entry.payload.originalTickets
              displayValue = originalValue.toLocaleString()
            } else if (entry.name === 'CSAT Improvement') {
              originalValue = entry.payload.originalCSAT
              displayValue = `+${originalValue.toFixed(1)}`
            }

            return (
              <p key={index} className="text-sm" style={{ color: entry.color }}>
                {entry.name}: <span className="font-semibold">{displayValue}</span>
              </p>
            )
          })}
        </div>
      )
    }
    return null
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Impact Over Time</CardTitle>
        <p className="text-sm text-muted-foreground mt-1">
          Cumulative improvements across key metrics (Last 30 days)
        </p>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={350}>
          <AreaChart data={normalizedData}>
            <defs>
              <linearGradient id="colorSavings" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10b981" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#10b981" stopOpacity={0.1}/>
              </linearGradient>
              <linearGradient id="colorTickets" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0.1}/>
              </linearGradient>
              <linearGradient id="colorCSAT" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0.1}/>
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis
              dataKey="date"
              tickFormatter={(value) => {
                const date = new Date(value)
                return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
              }}
              stroke="#6b7280"
              fontSize={12}
            />
            <YAxis
              stroke="#6b7280"
              fontSize={12}
              label={{ value: 'Normalized Impact (0-100)', angle: -90, position: 'insideLeft', style: { fontSize: 12 } }}
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend
              wrapperStyle={{ fontSize: '14px', paddingTop: '10px' }}
            />
            <Area
              type="monotone"
              dataKey="Cost Savings"
              stackId="1"
              stroke="#10b981"
              strokeWidth={2}
              fill="url(#colorSavings)"
            />
            <Area
              type="monotone"
              dataKey="Support Tickets"
              stackId="1"
              stroke="#3b82f6"
              strokeWidth={2}
              fill="url(#colorTickets)"
            />
            <Area
              type="monotone"
              dataKey="CSAT Improvement"
              stackId="1"
              stroke="#8b5cf6"
              strokeWidth={2}
              fill="url(#colorCSAT)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
