'use client'

import { useQuery } from '@tanstack/react-query'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Lightbulb, TrendingDown, Zap, Database, AlertTriangle, CheckCircle2, ArrowRight } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface OptimizationRecommendation {
  id: string
  title: string
  description: string
  priority: 'high' | 'medium' | 'low'
  potential_savings_usd: number
  effort: 'easy' | 'moderate' | 'complex'
  category: 'caching' | 'model-selection' | 'token-optimization' | 'batch-processing'
  agent_ids?: string[]
  steps: string[]
}

interface OptimizationRecommendationsModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  timeRange?: string
}

/**
 * OptimizationRecommendationsModal - AI-powered cost optimization suggestions
 *
 * Features:
 * - Prioritized list of optimization opportunities
 * - Potential savings calculation
 * - Implementation difficulty rating
 * - Step-by-step action items
 * - Agent-specific recommendations
 *
 * PRD Tab 3: Action Modal 2 - Optimization Suggestions
 */
export function OptimizationRecommendationsModal({
  open,
  onOpenChange,
  timeRange = '30d'
}: OptimizationRecommendationsModalProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['cost-optimization-recommendations', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/optimization-recommendations?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.recommendations as OptimizationRecommendation[]
    },
    enabled: open && !!user?.workspace_id,
  })

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case 'high':
        return { variant: 'destructive' as const, icon: AlertTriangle, label: 'High Priority' }
      case 'medium':
        return { variant: 'default' as const, icon: Zap, label: 'Medium Priority' }
      case 'low':
        return { variant: 'secondary' as const, icon: CheckCircle2, label: 'Low Priority' }
      default:
        return { variant: 'default' as const, icon: Zap, label: 'Medium Priority' }
    }
  }

  const getEffortBadge = (effort: string) => {
    switch (effort) {
      case 'easy':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
      case 'moderate':
        return 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200'
      case 'complex':
        return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
    }
  }

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'caching':
        return Database
      case 'model-selection':
        return Zap
      case 'token-optimization':
        return TrendingDown
      case 'batch-processing':
        return CheckCircle2
      default:
        return Lightbulb
    }
  }

  const totalSavings = data?.reduce((sum, rec) => sum + rec.potential_savings_usd, 0) || 0

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[700px] max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Lightbulb className="h-5 w-5 text-amber-500" />
            Cost Optimization Recommendations
          </DialogTitle>
          <DialogDescription>
            AI-powered suggestions to reduce costs while maintaining quality
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Summary */}
          {data && data.length > 0 && (
            <div className="p-4 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-950 dark:to-emerald-950 rounded-lg border border-green-200 dark:border-green-800">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground mb-1">Total Potential Savings</p>
                  <p className="text-3xl font-bold text-green-600">
                    ${totalSavings.toFixed(2)}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {data.length} optimization{data.length !== 1 ? 's' : ''} identified
                  </p>
                </div>
                <TrendingDown className="h-12 w-12 text-green-600" />
              </div>
            </div>
          )}

          {/* Loading State */}
          {isLoading && (
            <div className="space-y-3">
              <Skeleton className="h-32 w-full" />
              <Skeleton className="h-32 w-full" />
              <Skeleton className="h-32 w-full" />
            </div>
          )}

          {/* Error State */}
          {error && (
            <Alert variant="destructive">
              <AlertDescription>
                Failed to load optimization recommendations. Please try again later.
              </AlertDescription>
            </Alert>
          )}

          {/* Recommendations List */}
          {data && data.length > 0 && (
            <div className="space-y-3">
              {data.map((recommendation, index) => {
                const priorityBadge = getPriorityBadge(recommendation.priority)
                const PriorityIcon = priorityBadge.icon
                const CategoryIcon = getCategoryIcon(recommendation.category)

                return (
                  <div
                    key={recommendation.id}
                    className="p-4 border rounded-lg hover:border-primary/50 transition-colors"
                  >
                    {/* Header */}
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex items-start gap-3 flex-1">
                        <div className="p-2 bg-primary/10 rounded">
                          <CategoryIcon className="h-5 w-5 text-primary" />
                        </div>
                        <div className="flex-1">
                          <h4 className="font-semibold text-sm mb-1">{recommendation.title}</h4>
                          <p className="text-xs text-muted-foreground">{recommendation.description}</p>
                        </div>
                      </div>
                      <div className="flex flex-col items-end gap-2">
                        <span className="text-lg font-bold text-green-600">
                          -${recommendation.potential_savings_usd.toFixed(2)}
                        </span>
                      </div>
                    </div>

                    {/* Badges */}
                    <div className="flex items-center gap-2 mb-3">
                      <Badge variant={priorityBadge.variant} className="text-xs">
                        <PriorityIcon className="h-3 w-3 mr-1" />
                        {priorityBadge.label}
                      </Badge>
                      <span className={`text-xs px-2 py-1 rounded font-medium ${getEffortBadge(recommendation.effort)}`}>
                        {recommendation.effort.charAt(0).toUpperCase() + recommendation.effort.slice(1)}
                      </span>
                      <span className="text-xs px-2 py-1 rounded font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                        {recommendation.category.replace('-', ' ')}
                      </span>
                    </div>

                    {/* Affected Agents */}
                    {recommendation.agent_ids && recommendation.agent_ids.length > 0 && (
                      <div className="mb-3">
                        <p className="text-xs text-muted-foreground mb-1">Affected agents:</p>
                        <div className="flex flex-wrap gap-1">
                          {recommendation.agent_ids.slice(0, 3).map((agentId) => (
                            <span key={agentId} className="text-xs px-2 py-0.5 rounded bg-muted font-mono">
                              {agentId}
                            </span>
                          ))}
                          {recommendation.agent_ids.length > 3 && (
                            <span className="text-xs px-2 py-0.5 rounded bg-muted text-muted-foreground">
                              +{recommendation.agent_ids.length - 3} more
                            </span>
                          )}
                        </div>
                      </div>
                    )}

                    {/* Implementation Steps */}
                    <div className="pt-3 border-t">
                      <p className="text-xs font-semibold mb-2">Implementation Steps:</p>
                      <ol className="space-y-1">
                        {recommendation.steps.map((step, stepIndex) => (
                          <li key={stepIndex} className="text-xs text-muted-foreground flex items-start gap-2">
                            <span className="font-bold">{stepIndex + 1}.</span>
                            <span>{step}</span>
                          </li>
                        ))}
                      </ol>
                    </div>
                  </div>
                )
              })}
            </div>
          )}

          {/* No Recommendations */}
          {data && data.length === 0 && (
            <div className="p-8 text-center">
              <CheckCircle2 className="h-12 w-12 text-green-600 mx-auto mb-3" />
              <p className="text-sm font-medium">Great job!</p>
              <p className="text-xs text-muted-foreground mt-1">
                Your cost optimization is already at its best. No recommendations at this time.
              </p>
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2 pt-4 border-t">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
          {data && data.length > 0 && (
            <Button onClick={() => {
              // Could navigate to detailed implementation guide
              onOpenChange(false)
            }}>
              View Implementation Guide
              <ArrowRight className="h-4 w-4 ml-2" />
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
