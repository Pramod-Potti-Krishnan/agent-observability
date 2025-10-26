import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { Shield, AlertTriangle, Zap } from 'lucide-react'

interface TypeData {
  pii: number
  toxicity: number
  injection: number
}

interface TypeBreakdownProps {
  data: TypeData
  loading?: boolean
}

const COLORS = {
  pii: '#3b82f6', // blue
  toxicity: '#ef4444', // red
  injection: '#f97316' // orange
}

const ICONS = {
  pii: Shield,
  toxicity: AlertTriangle,
  injection: Zap
}

export function TypeBreakdown({ data, loading = false }: TypeBreakdownProps) {
  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Violation Types</CardTitle>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[300px] w-full" />
        </CardContent>
      </Card>
    )
  }

  const total = data.pii + data.toxicity + data.injection

  if (total === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Violation Types</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center text-muted-foreground">
            No violations detected - your agents are safe!
          </div>
        </CardContent>
      </Card>
    )
  }

  const chartData = [
    { name: 'PII Detection', value: data.pii, type: 'pii' },
    { name: 'Toxicity', value: data.toxicity, type: 'toxicity' },
    { name: 'Prompt Injection', value: data.injection, type: 'injection' }
  ].filter(item => item.value > 0)

  return (
    <Card>
      <CardHeader>
        <CardTitle>Violation Types</CardTitle>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <PieChart>
            <Pie
              data={chartData}
              dataKey="value"
              nameKey="name"
              cx="50%"
              cy="50%"
              outerRadius={100}
              label={(entry) => {
                const percentage = ((entry.value / total) * 100).toFixed(1)
                return `${entry.name}: ${percentage}%`
              }}
            >
              {chartData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[entry.type as keyof typeof COLORS]} />
              ))}
            </Pie>
            <Tooltip
              formatter={(value: number) => [
                `${value.toLocaleString()} violations (${((value / total) * 100).toFixed(1)}%)`,
                ''
              ]}
            />
          </PieChart>
        </ResponsiveContainer>

        {/* Legend with icons and counts */}
        <div className="mt-4 space-y-2">
          {chartData.map((item) => {
            const Icon = ICONS[item.type as keyof typeof ICONS]
            const percentage = ((item.value / total) * 100).toFixed(1)

            return (
              <div key={item.type} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Icon
                    className="h-4 w-4"
                    style={{ color: COLORS[item.type as keyof typeof COLORS] }}
                  />
                  <span className="text-sm">{item.name}</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium">{item.value.toLocaleString()}</span>
                  <span className="text-xs text-muted-foreground">({percentage}%)</span>
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}
