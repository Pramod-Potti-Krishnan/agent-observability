'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'

interface QualityScoreCardProps {
  score: number // 0-10 scale
  trend: number // percentage change
  timeRange: string
  loading?: boolean
}

export function QualityScoreCard({
  score,
  trend,
  timeRange,
  loading = false
}: QualityScoreCardProps) {
  // Ensure values are numbers with null safety
  const safeScore = score || 0
  const safeTrend = trend || 0

  // Color coding: green if >8, yellow if 6-8, red if <6
  const getScoreColor = (score: number) => {
    if (score >= 8) return 'text-green-600'
    if (score >= 6) return 'text-yellow-600'
    return 'text-red-600'
  }

  const getScoreBgColor = (score: number) => {
    if (score >= 8) return 'bg-green-50'
    if (score >= 6) return 'bg-yellow-50'
    return 'bg-red-50'
  }

  const TrendIcon = ({ change }: { change: number }) => {
    if (change > 0) return <TrendingUp className="h-4 w-4 text-green-500" />
    if (change < 0) return <TrendingDown className="h-4 w-4 text-red-500" />
    return <Minus className="h-4 w-4 text-gray-500" />
  }

  return (
    <Card className={`hover:shadow-lg transition-shadow ${getScoreBgColor(safeScore)}`}>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          Overall Quality Score
        </CardTitle>
        <Badge
          variant={safeTrend > 0 ? "default" : safeTrend < 0 ? "destructive" : "secondary"}
          className="text-xs"
        >
          {safeTrend > 0 ? '+' : ''}{safeTrend.toFixed(1)}%
        </Badge>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="space-y-2">
            <Skeleton className="h-12 w-20" />
            <Skeleton className="h-4 w-32" />
          </div>
        ) : (
          <>
            <div className={`text-5xl font-bold ${getScoreColor(safeScore)}`}>
              {safeScore.toFixed(1)}
            </div>
            <p className="text-xs text-muted-foreground mt-2 flex items-center gap-1">
              <TrendIcon change={safeTrend} />
              <span className={safeTrend > 0 ? 'text-green-600' : safeTrend < 0 ? 'text-red-600' : 'text-gray-500'}>
                {Math.abs(safeTrend).toFixed(1)}%
              </span>
              <span>vs last {timeRange}</span>
            </p>
            <div className="mt-3 text-xs text-muted-foreground">
              Out of 10.0 scale
            </div>
          </>
        )}
      </CardContent>
    </Card>
  )
}
