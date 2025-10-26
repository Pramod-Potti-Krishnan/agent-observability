import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { Badge } from '@/components/ui/badge'
import { Mail, Star, DollarSign, Zap, Target } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'

interface Goal {
  id: string
  metric: string
  name: string
  description?: string
  target_value: string
  current_value: string
  progress_percentage: number
  unit: string
}

interface GoalProgressCardProps {
  goals: Goal[]
  loading?: boolean
}

const goalIcons: Record<string, React.ReactNode> = {
  'support_tickets': <Mail className="h-5 w-5" />,
  'csat_score': <Star className="h-5 w-5" />,
  'cost_savings': <DollarSign className="h-5 w-5" />,
  'response_time': <Zap className="h-5 w-5" />,
  'accuracy': <Target className="h-5 w-5" />
}

export function GoalProgressCard({ goals, loading = false }: GoalProgressCardProps) {
  const getProgressColor = (progress: number) => {
    if (progress >= 80) return 'bg-green-500'
    if (progress >= 60) return 'bg-yellow-500'
    return 'bg-red-500'
  }

  const getProgressBarClassName = (progress: number) => {
    if (progress >= 80) return 'bg-green-500'
    if (progress >= 60) return 'bg-yellow-500'
    return 'bg-red-500'
  }

  const formatValue = (value: number, unit: string) => {
    switch (unit) {
      case 'USD':
        return `$${value.toLocaleString()}`
      case 'seconds':
        return `${value}s`
      case '%':
        return `${value}%`
      case 'score':
        return value.toFixed(1)
      default:
        return value.toLocaleString()
    }
  }

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Business Goals Progress</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="space-y-2">
                <Skeleton className="h-5 w-48" />
                <Skeleton className="h-3 w-full" />
                <Skeleton className="h-4 w-32" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    )
  }

  if (!goals || goals.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Business Goals Progress</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            No business goals configured
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Business Goals Progress</CardTitle>
        <p className="text-sm text-muted-foreground mt-1">
          Track progress toward key business objectives
        </p>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {goals.map((goal) => {
            const progress = Math.min(goal.progress_percentage, 100)
            const isAchieved = progress >= 100
            const isNearlyThere = progress >= 90 && progress < 100

            return (
              <div key={goal.id} className="space-y-2">
                {/* Goal Header */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="text-primary">
                      {goalIcons[goal.metric] || <Target className="h-5 w-5" />}
                    </div>
                    <span className="font-semibold text-sm">{goal.name}</span>
                    {isAchieved && (
                      <Badge variant="default" className="text-xs">
                        🎉 Achieved!
                      </Badge>
                    )}
                    {isNearlyThere && !isAchieved && (
                      <Badge variant="secondary" className="text-xs">
                        🎯 Nearly There!
                      </Badge>
                    )}
                  </div>
                  <span className="text-sm font-medium text-muted-foreground">
                    {progress.toFixed(0)}%
                  </span>
                </div>

                {/* Progress Bar */}
                <div className="relative">
                  <Progress value={progress} className="h-3" />
                  <div
                    className={`absolute inset-0 h-3 rounded-full transition-all ${getProgressBarClassName(progress)}`}
                    style={{ width: `${progress}%` }}
                  />
                </div>

                {/* Current vs Target */}
                <div className="flex justify-between text-xs text-muted-foreground">
                  <span>
                    Current: <span className="font-semibold text-foreground">
                      {formatValue(parseFloat(goal.current_value), goal.unit)}
                    </span>
                  </span>
                  <span>
                    Target: <span className="font-semibold text-foreground">
                      {formatValue(parseFloat(goal.target_value), goal.unit)}
                    </span>
                  </span>
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}
