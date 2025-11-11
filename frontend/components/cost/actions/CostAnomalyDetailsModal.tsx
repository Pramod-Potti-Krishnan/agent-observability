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
import { AlertTriangle, Clock, TrendingUp, CheckCircle2 } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface Anomaly {
  timestamp: string
  actual_cost: number
  expected_cost: number
  deviation_percentage: number
  severity: 'low' | 'medium' | 'high' | 'critical'
  reason: string
  agent_id?: string
}

interface CostAnomalyDetailsModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  timeRange?: string
}

export function CostAnomalyDetailsModal({
  open,
  onOpenChange,
  timeRange = '7d'
}: CostAnomalyDetailsModalProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['cost-anomalies-detailed', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/anomalies?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data
    },
    enabled: open && !!user?.workspace_id,
  })

  const getSeverityBadge = (severity: string) => {
    const styles = {
      critical: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
      high: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200',
      medium: 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200',
      low: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
    }
    return styles[severity as keyof typeof styles] || styles.low
  }

  const anomalies = data?.anomalies || []
  const criticalCount = anomalies.filter((a: Anomaly) => a.severity === 'critical').length

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[700px] max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-amber-500" />
            Cost Anomaly Details
          </DialogTitle>
          <DialogDescription>
            Review unusual spending patterns and investigate root causes
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {isLoading && <Skeleton className="h-[400px] w-full" />}

          {error && (
            <Alert variant="destructive">
              <AlertDescription>Failed to load anomaly data</AlertDescription>
            </Alert>
          )}

          {data && (
            <>
              {/* Summary */}
              <div className="grid grid-cols-3 gap-4">
                <div className="p-4 bg-muted rounded-lg">
                  <p className="text-xs text-muted-foreground mb-1">Total Anomalies</p>
                  <p className="text-2xl font-bold">{data.total_anomalies || 0}</p>
                </div>
                <div className="p-4 bg-red-50 dark:bg-red-950 rounded-lg border border-red-200 dark:border-red-800">
                  <p className="text-xs text-muted-foreground mb-1">Critical Alerts</p>
                  <p className="text-2xl font-bold text-red-600">{data.critical_anomalies || 0}</p>
                </div>
                <div className="p-4 bg-muted rounded-lg">
                  <p className="text-xs text-muted-foreground mb-1">Last 24h</p>
                  <p className="text-2xl font-bold">
                    {anomalies.filter((a: Anomaly) => {
                      const hoursSince = (Date.now() - new Date(a.timestamp).getTime()) / (1000 * 60 * 60)
                      return hoursSince <= 24
                    }).length}
                  </p>
                </div>
              </div>

              {/* Anomalies List */}
              {anomalies.length > 0 ? (
                <div className="space-y-3">
                  {anomalies
                    .sort((a: Anomaly, b: Anomaly) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
                    .map((anomaly: Anomaly, index: number) => (
                      <div
                        key={index}
                        className={`p-4 border rounded-lg ${
                          anomaly.severity === 'critical' ? 'border-red-300 bg-red-50 dark:bg-red-950' : ''
                        }`}
                      >
                        <div className="flex items-start justify-between mb-2">
                          <div className="flex items-center gap-2">
                            <span className={`text-xs px-2 py-1 rounded font-medium ${getSeverityBadge(anomaly.severity)}`}>
                              {anomaly.severity}
                            </span>
                            <span className="text-xs text-muted-foreground flex items-center gap-1">
                              <Clock className="h-3 w-3" />
                              {new Date(anomaly.timestamp).toLocaleString('en-US', {
                                month: 'short',
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
                            </span>
                          </div>
                          <div className="text-right">
                            <span className={`text-sm font-bold ${
                              anomaly.deviation_percentage > 0 ? 'text-red-600' : 'text-green-600'
                            }`}>
                              {anomaly.deviation_percentage > 0 ? '+' : ''}
                              {anomaly.deviation_percentage.toFixed(1)}%
                            </span>
                          </div>
                        </div>

                        <div className="space-y-2">
                          <p className="text-sm">{anomaly.reason}</p>
                          {anomaly.agent_id && (
                            <p className="text-xs text-muted-foreground">
                              Agent: <span className="font-mono">{anomaly.agent_id}</span>
                            </p>
                          )}
                          <div className="flex items-center gap-4 text-xs">
                            <span>
                              <span className="text-muted-foreground">Actual:</span>
                              <span className="font-medium ml-1">${anomaly.actual_cost.toFixed(2)}</span>
                            </span>
                            <span>
                              <span className="text-muted-foreground">Expected:</span>
                              <span className="font-medium ml-1">${anomaly.expected_cost.toFixed(2)}</span>
                            </span>
                          </div>
                        </div>
                      </div>
                    ))}
                </div>
              ) : (
                <div className="p-8 bg-green-50 dark:bg-green-950 rounded-lg border border-green-200 dark:border-green-800 text-center">
                  <CheckCircle2 className="h-12 w-12 text-green-600 mx-auto mb-3" />
                  <p className="text-sm font-medium text-green-900 dark:text-green-100">
                    No anomalies detected
                  </p>
                  <p className="text-xs text-green-700 dark:text-green-300 mt-1">
                    Your spending is within expected patterns
                  </p>
                </div>
              )}

              {criticalCount > 0 && (
                <Alert>
                  <AlertTriangle className="h-4 w-4" />
                  <AlertDescription className="text-xs">
                    <strong>{criticalCount} critical anomal{criticalCount !== 1 ? 'ies' : 'y'} detected.</strong> These represent spending exceeding expected cost by more than 50%. Investigate immediately to prevent budget overruns.
                  </AlertDescription>
                </Alert>
              )}

              <p className="text-xs text-muted-foreground text-center">
                Anomalies are detected using statistical analysis with 2σ confidence intervals.
              </p>
            </>
          )}
        </div>

        <div className="flex justify-end pt-4 border-t">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
