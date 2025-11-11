'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ReferenceLine } from 'recharts'

interface CriteriaData {
  accuracy: number
  relevance: number
  helpfulness: number
  coherence: number
}

interface CriteriaBreakdownProps {
  data: CriteriaData
  loading?: boolean
}

export function CriteriaBreakdown({ data, loading = false }: CriteriaBreakdownProps) {
  // Ensure values are numbers with null safety
  const safeData = {
    accuracy: data.accuracy || 0,
    relevance: data.relevance || 0,
    helpfulness: data.helpfulness || 0,
    coherence: data.coherence || 0
  }

  const chartData = [
    { name: 'Accuracy', score: safeData.accuracy },
    { name: 'Relevance', score: safeData.relevance },
    { name: 'Helpfulness', score: safeData.helpfulness },
    { name: 'Coherence', score: safeData.coherence }
  ]

  const getBarColor = (score: number) => {
    if (score >= 8) return '#22c55e' // green-500
    if (score >= 6) return '#eab308' // yellow-500
    return '#ef4444' // red-500
  }

  const CustomBar = (props: any) => {
    const { fill, x, y, width, height, score } = props
    const color = getBarColor(score)
    return <rect x={x} y={y} width={width} height={height} fill={color} />
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Evaluation Criteria Breakdown</CardTitle>
      </CardHeader>
      <CardContent>
        {loading ? (
          <Skeleton className="h-[300px] w-full" />
        ) : (
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
              <XAxis type="number" domain={[0, 10]} ticks={[0, 2, 4, 6, 8, 10]} />
              <YAxis type="category" dataKey="name" width={100} />
              <Tooltip
                formatter={(value: number) => [value.toFixed(2), 'Score']}
                contentStyle={{
                  backgroundColor: 'rgba(255, 255, 255, 0.95)',
                  border: '1px solid #ccc',
                  borderRadius: '4px'
                }}
              />
              <Legend />
              <ReferenceLine x={8} stroke="#22c55e" strokeDasharray="3 3" label="Target: 8.0" />
              <Bar
                dataKey="score"
                fill="#8884d8"
                name="Score"
                shape={<CustomBar />}
                radius={[0, 4, 4, 0]}
              />
            </BarChart>
          </ResponsiveContainer>
        )}
        <div className="mt-4 grid grid-cols-4 gap-2 text-center text-xs">
          {chartData.map((item) => (
            <div key={item.name} className="space-y-1">
              <div className="font-medium text-muted-foreground">{item.name}</div>
              <div className={`text-lg font-bold ${
                item.score >= 8 ? 'text-green-600' :
                item.score >= 6 ? 'text-yellow-600' :
                'text-red-600'
              }`}>
                {item.score.toFixed(1)}
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
