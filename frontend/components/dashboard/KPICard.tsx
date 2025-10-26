import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

interface KPICardProps {
  title: string
  value: string
  change: number
  changeLabel: string
  trend?: 'normal' | 'inverse'
  loading?: boolean
}

export function KPICard({
  title,
  value,
  change,
  changeLabel,
  trend = 'normal',
  loading = false
}: KPICardProps) {
  // Determine if change is positive based on trend
  const isPositive = trend === 'inverse' ? change < 0 : change > 0
  const isNeutral = change === 0

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <Badge
          variant={
            isPositive ? "default" : isNeutral ? "secondary" : "destructive"
          }
          className="text-xs"
        >
          {change > 0 ? '+' : ''}{change.toFixed(1)}%
        </Badge>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="animate-pulse">
            <div className="h-8 bg-muted rounded w-24 mb-2"></div>
            <div className="h-4 bg-muted rounded w-32"></div>
          </div>
        ) : (
          <>
            <div className="text-3xl font-bold">{value}</div>
            <p className="text-xs text-muted-foreground mt-1">
              <span
                className={
                  isPositive
                    ? 'text-green-600'
                    : isNeutral
                    ? 'text-gray-500'
                    : 'text-red-600'
                }
              >
                {change > 0 ? '+' : ''}
                {change.toFixed(1)}%
              </span>{' '}
              {changeLabel}
            </p>
          </>
        )}
      </CardContent>
    </Card>
  )
}
