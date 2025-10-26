'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import apiClient from '@/lib/api-client'
import { useQuery } from '@tanstack/react-query'

interface Activity {
  trace_id: string
  agent_id: string
  action: string
  status: 'success' | 'error' | 'timeout'
  timestamp: string
  metadata: {
    latency_ms?: number
    model?: string
    cost_usd?: number
  }
}

export function ActivityStream() {
  const { data, isLoading } = useQuery({
    queryKey: ['activity', 'stream'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/activity/stream?limit=50')
      return response.data.items as Activity[]
    },
    refetchInterval: 30000,
  })

  const getStatusVariant = (status: string): "default" | "destructive" | "secondary" => {
    switch (status) {
      case 'success':
        return 'default'
      case 'error':
        return 'destructive'
      default:
        return 'secondary'
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Activity</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-2">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="h-12 bg-muted rounded"></div>
              </div>
            ))}
          </div>
        ) : (
          <div className="border rounded-lg max-h-[400px] overflow-y-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[150px]">Agent</TableHead>
                  <TableHead>Model</TableHead>
                  <TableHead className="text-right">Latency</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data && data.length > 0 ? (
                  data.map((activity) => (
                    <TableRow key={activity.trace_id}>
                      <TableCell className="font-medium text-sm">
                        {activity.agent_id}
                      </TableCell>
                      <TableCell className="text-sm">
                        {activity.metadata.model || '-'}
                      </TableCell>
                      <TableCell className="text-right text-sm">
                        {activity.metadata.latency_ms || '-'} ms
                      </TableCell>
                      <TableCell>
                        <Badge variant={getStatusVariant(activity.status)}>
                          {activity.status}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center text-muted-foreground py-8">
                      No recent activity
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
