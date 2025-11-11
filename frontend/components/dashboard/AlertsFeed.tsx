'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert } from '@/components/ui/alert'
import { Badge } from '@/components/ui/badge'
import apiClient from '@/lib/api-client'
import { useQuery } from '@tanstack/react-query'
import { useAuth } from '@/lib/auth-context'

interface AlertItem {
  id: string
  title: string
  description: string
  severity: 'info' | 'warning' | 'critical'
  metric_value?: number
  created_at: string
}

export function AlertsFeed() {
  const { user } = useAuth()

  const { data, isLoading } = useQuery({
    queryKey: ['alerts', 'recent'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/alerts/recent?limit=10')
      return response.data.items as AlertItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000,
  })

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle>Recent Alerts</CardTitle>
          <Badge variant="outline">{data?.length || 0} active</Badge>
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-2">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="h-20 bg-muted rounded"></div>
              </div>
            ))}
          </div>
        ) : data && data.length > 0 ? (
          <div className="space-y-3 max-h-[400px] overflow-y-auto">
            {data.map((alert) => (
              <Alert
                key={alert.id}
                className={
                  alert.severity === 'critical'
                    ? 'border-red-500 bg-red-50'
                    : alert.severity === 'warning'
                    ? 'border-yellow-500 bg-yellow-50'
                    : 'border-blue-500 bg-blue-50'
                }
              >
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium">{alert.title}</p>
                    <Badge
                      variant={alert.severity === 'critical' ? 'destructive' : 'default'}
                      className="text-xs"
                    >
                      {alert.severity}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    {alert.description}
                  </p>
                </div>
              </Alert>
            ))}
          </div>
        ) : (
          <p className="text-sm text-muted-foreground text-center py-8">
            No alerts at this time
          </p>
        )}
      </CardContent>
    </Card>
  )
}
