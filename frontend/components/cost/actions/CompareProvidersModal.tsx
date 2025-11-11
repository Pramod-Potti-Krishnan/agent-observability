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
import { ResponsiveContainer, ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, ZAxis } from 'recharts'
import { Target, Award, TrendingUp, DollarSign } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface ProviderComparison {
  provider: string
  avg_cost_per_request: number
  quality_score: number
  total_requests: number
  total_cost: number
  color: string
}

interface CompareProvidersModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  timeRange?: string
}

export function CompareProvidersModal({
  open,
  onOpenChange,
  timeRange = '30d'
}: CompareProvidersModalProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['provider-comparison', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/provider-matrix?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data
    },
    enabled: open && !!user?.workspace_id,
  })

  const getQuadrant = (cost: number, quality: number) => {
    const avgCost = data?.providers.reduce((sum: number, p: ProviderComparison) => sum + p.avg_cost_per_request, 0) / (data?.providers.length || 1)
    const avgQuality = data?.providers.reduce((sum: number, p: ProviderComparison) => sum + p.quality_score, 0) / (data?.providers.length || 1)

    if (quality > avgQuality && cost < avgCost) return { label: 'Optimal', color: 'text-green-600 bg-green-50 dark:bg-green-950' }
    if (quality > avgQuality && cost > avgCost) return { label: 'Premium', color: 'text-blue-600 bg-blue-50 dark:bg-blue-950' }
    if (quality < avgQuality && cost < avgCost) return { label: 'Budget', color: 'text-amber-600 bg-amber-50 dark:bg-amber-950' }
    return { label: 'Review', color: 'text-red-600 bg-red-50 dark:bg-red-950' }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[800px] max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Target className="h-5 w-5" />
            Provider Cost & Performance Comparison
          </DialogTitle>
          <DialogDescription>
            Compare AI providers by cost efficiency and quality
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {isLoading && <Skeleton className="h-[400px] w-full" />}

          {error && (
            <Alert variant="destructive">
              <AlertDescription>Failed to load provider data</AlertDescription>
            </Alert>
          )}

          {data && data.providers && data.providers.length > 0 && (
            <>
              {/* Best Value */}
              {data.best_value_provider && (
                <div className="p-4 bg-green-50 dark:bg-green-950 rounded-lg border border-green-200 dark:border-green-800">
                  <div className="flex items-center gap-2 mb-1">
                    <Award className="h-4 w-4 text-green-600" />
                    <span className="text-sm font-semibold">Best Value Provider</span>
                  </div>
                  <p className="text-lg font-bold text-green-700">{data.best_value_provider}</p>
                </div>
              )}

              {/* Scatter Plot */}
              <ResponsiveContainer width="100%" height={350}>
                <ScatterChart margin={{ top: 20, right: 30, left: 20, bottom: 20 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    type="number"
                    dataKey="avg_cost_per_request"
                    name="Cost per Request"
                    tick={{ fontSize: 11 }}
                    label={{ value: 'Cost per Request ($)', position: 'bottom', fontSize: 12 }}
                    tickFormatter={(value) => `$${value.toFixed(4)}`}
                  />
                  <YAxis
                    type="number"
                    dataKey="quality_score"
                    name="Quality Score"
                    tick={{ fontSize: 11 }}
                    label={{ value: 'Quality Score', angle: -90, position: 'insideLeft', fontSize: 12 }}
                    domain={[0, 100]}
                  />
                  <ZAxis type="number" dataKey="total_requests" range={[100, 1000]} name="Requests" />
                  <Tooltip
                    formatter={(value: any, name: string) => {
                      if (name === 'avg_cost_per_request') return `$${value.toFixed(4)}`
                      if (name === 'quality_score') return `${value.toFixed(1)}/100`
                      return value.toLocaleString()
                    }}
                  />
                  <Scatter name="Providers" data={data.providers} fill="#8884d8" />
                </ScatterChart>
              </ResponsiveContainer>

              {/* Provider Table */}
              <div className="border rounded-lg overflow-hidden">
                <table className="w-full text-sm">
                  <thead className="bg-muted">
                    <tr>
                      <th className="text-left p-3 font-semibold">Provider</th>
                      <th className="text-right p-3 font-semibold">Cost/Request</th>
                      <th className="text-right p-3 font-semibold">Quality</th>
                      <th className="text-right p-3 font-semibold">Requests</th>
                      <th className="text-center p-3 font-semibold">Zone</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.providers.map((provider: ProviderComparison, index: number) => {
                      const zone = getQuadrant(provider.avg_cost_per_request, provider.quality_score)
                      return (
                        <tr key={index} className="border-t hover:bg-muted/50">
                          <td className="p-3 font-medium">{provider.provider}</td>
                          <td className="p-3 text-right">${provider.avg_cost_per_request.toFixed(4)}</td>
                          <td className="p-3 text-right">{provider.quality_score.toFixed(1)}/100</td>
                          <td className="p-3 text-right">{provider.total_requests.toLocaleString()}</td>
                          <td className="p-3 text-center">
                            <span className={`text-xs px-2 py-1 rounded font-medium ${zone.color}`}>
                              {zone.label}
                            </span>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>

              {/* Legend */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs">
                <div className="flex items-center gap-2 p-2 bg-green-50 dark:bg-green-950 rounded">
                  <div className="w-3 h-3 rounded bg-green-500"></div>
                  <span>Optimal (High Quality, Low Cost)</span>
                </div>
                <div className="flex items-center gap-2 p-2 bg-blue-50 dark:bg-blue-950 rounded">
                  <div className="w-3 h-3 rounded bg-blue-500"></div>
                  <span>Premium (High Quality, High Cost)</span>
                </div>
                <div className="flex items-center gap-2 p-2 bg-amber-50 dark:bg-amber-950 rounded">
                  <div className="w-3 h-3 rounded bg-amber-500"></div>
                  <span>Budget (Low Quality, Low Cost)</span>
                </div>
                <div className="flex items-center gap-2 p-2 bg-red-50 dark:bg-red-950 rounded">
                  <div className="w-3 h-3 rounded bg-red-500"></div>
                  <span>Review (Low Quality, High Cost)</span>
                </div>
              </div>
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
