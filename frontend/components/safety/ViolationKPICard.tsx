import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { AlertTriangle, Shield, Zap } from 'lucide-react'

interface ViolationKPICardProps {
  totalViolations: number
  criticalCount: number
  highCount: number
  mediumCount: number
  trend: number // percentage change
  loading?: boolean
}

export function ViolationKPICard({
  totalViolations,
  criticalCount,
  highCount,
  mediumCount,
  trend,
  loading = false
}: ViolationKPICardProps) {
  if (loading) {
    return (
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader>
          <CardTitle className="text-sm font-medium text-muted-foreground">
            Total Violations
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="animate-pulse">
            <div className="h-8 bg-muted rounded w-24 mb-4"></div>
            <div className="h-4 bg-muted rounded w-full mb-2"></div>
            <div className="h-4 bg-muted rounded w-full mb-2"></div>
            <div className="h-4 bg-muted rounded w-full"></div>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          Total Violations
        </CardTitle>
        <Badge
          variant={trend > 0 ? "destructive" : trend < 0 ? "default" : "secondary"}
          className="text-xs"
        >
          {trend > 0 ? '+' : ''}{trend.toFixed(1)}%
        </Badge>
      </CardHeader>
      <CardContent>
        <div className="text-3xl font-bold mb-4">{totalViolations.toLocaleString()}</div>

        <div className="space-y-2">
          {/* Critical Violations */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-red-500" />
              <span className="text-sm text-muted-foreground">Critical</span>
            </div>
            <Badge className="bg-red-100 text-red-800 border-red-500 hover:bg-red-100">
              {criticalCount}
            </Badge>
          </div>

          {/* High Violations */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Zap className="h-4 w-4 text-orange-500" />
              <span className="text-sm text-muted-foreground">High</span>
            </div>
            <Badge className="bg-orange-100 text-orange-800 border-orange-500 hover:bg-orange-100">
              {highCount}
            </Badge>
          </div>

          {/* Medium Violations */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Shield className="h-4 w-4 text-yellow-500" />
              <span className="text-sm text-muted-foreground">Medium</span>
            </div>
            <Badge className="bg-yellow-100 text-yellow-800 border-yellow-500 hover:bg-yellow-100">
              {mediumCount}
            </Badge>
          </div>
        </div>

        <p className="text-xs text-muted-foreground mt-4">
          <span
            className={
              trend > 0
                ? 'text-red-600'
                : trend < 0
                ? 'text-green-600'
                : 'text-gray-500'
            }
          >
            {trend > 0 ? '+' : ''}
            {trend.toFixed(1)}%
          </span>{' '}
          vs last period
        </p>
      </CardContent>
    </Card>
  )
}
