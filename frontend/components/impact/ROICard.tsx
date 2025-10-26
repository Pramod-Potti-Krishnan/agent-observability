import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown, Info } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'

interface ROICardProps {
  totalSavings: number
  investment: number
  roi: number
  period: string
  loading?: boolean
}

export function ROICard({
  totalSavings,
  investment,
  roi,
  period,
  loading = false
}: ROICardProps) {
  // Determine ROI color
  const getROIColor = () => {
    if (roi >= 100) return 'text-green-600'
    if (roi >= 50) return 'text-yellow-600'
    return 'text-red-600'
  }

  const getROIBadgeVariant = () => {
    if (roi >= 100) return 'default'
    if (roi >= 50) return 'secondary'
    return 'destructive'
  }

  if (loading) {
    return (
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader>
          <CardTitle className="text-sm font-medium text-muted-foreground">
            Return on Investment (ROI)
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-12 w-32 mb-4" />
          <Skeleton className="h-4 w-full mb-2" />
          <Skeleton className="h-4 w-full mb-2" />
          <Skeleton className="h-4 w-3/4" />
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          Return on Investment (ROI)
        </CardTitle>
        <div className="group relative">
          <Info className="h-4 w-4 text-muted-foreground cursor-help" />
          <div className="absolute right-0 top-6 w-64 p-2 bg-popover text-popover-foreground text-xs rounded-md shadow-lg opacity-0 group-hover:opacity-100 transition-opacity z-10 pointer-events-none">
            ROI = ((Total Savings - Investment) / Investment) × 100
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Main ROI Display */}
          <div className="flex items-baseline gap-2">
            <span className={`text-4xl font-bold ${getROIColor()}`}>
              {roi >= 0 ? '+' : ''}{roi.toFixed(0)}%
            </span>
            <Badge variant={getROIBadgeVariant()} className="text-xs">
              {period}
            </Badge>
          </div>

          {/* ROI Trend Indicator */}
          <div className="flex items-center gap-2">
            {roi > 0 ? (
              <TrendingUp className="h-5 w-5 text-green-500" />
            ) : (
              <TrendingDown className="h-5 w-5 text-red-500" />
            )}
            <span className="text-sm text-muted-foreground">
              {roi > 0 ? 'Positive returns' : 'Negative returns'}
            </span>
          </div>

          {/* Calculation Breakdown */}
          <div className="space-y-2 pt-2 border-t">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Total Savings:</span>
              <span className="font-semibold text-green-600">
                ${totalSavings.toLocaleString()}
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Investment:</span>
              <span className="font-semibold">
                ${investment.toLocaleString()}
              </span>
            </div>
            <div className="flex justify-between text-sm pt-2 border-t">
              <span className="text-muted-foreground">Net Gain:</span>
              <span className={`font-bold ${totalSavings - investment >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                ${(totalSavings - investment).toLocaleString()}
              </span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
