import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { TrendingUp, TrendingDown, Minus, CheckCircle2, XCircle } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'

interface Metric {
  category: string
  before: string | number
  after: string | number
  improvement: string
  improvementValue: number
  status: 'improved' | 'declined' | 'unchanged'
}

interface MetricsTableProps {
  metrics: Metric[]
  loading?: boolean
}

export function MetricsTable({ metrics, loading = false }: MetricsTableProps) {
  const StatusIcon = ({ status }: { status: 'improved' | 'declined' | 'unchanged' }) => {
    switch (status) {
      case 'improved':
        return <CheckCircle2 className="h-4 w-4 text-green-500" />
      case 'declined':
        return <XCircle className="h-4 w-4 text-red-500" />
      case 'unchanged':
        return <Minus className="h-4 w-4 text-gray-500" />
    }
  }

  const TrendIcon = ({ value }: { value: number }) => {
    if (value > 0) return <TrendingUp className="h-4 w-4 text-green-500" />
    if (value < 0) return <TrendingDown className="h-4 w-4 text-red-500" />
    return <Minus className="h-4 w-4 text-gray-500" />
  }

  const getImprovementColor = (value: number) => {
    if (value > 0) return 'text-green-600 font-semibold'
    if (value < 0) return 'text-red-600 font-semibold'
    return 'text-gray-500'
  }

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Key Business Metrics</CardTitle>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[400px] w-full" />
        </CardContent>
      </Card>
    )
  }

  if (!metrics || metrics.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Key Business Metrics</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            No metrics data available
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Key Business Metrics</CardTitle>
        <p className="text-sm text-muted-foreground mt-1">
          Before and after comparison showing the impact of AI agents
        </p>
      </CardHeader>
      <CardContent>
        <div className="overflow-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[250px]">Category</TableHead>
                <TableHead className="text-right">Before</TableHead>
                <TableHead className="text-right">After</TableHead>
                <TableHead className="text-right">Improvement</TableHead>
                <TableHead className="text-center">Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {metrics.map((metric, idx) => (
                <TableRow key={idx} className="hover:bg-muted/50">
                  <TableCell className="font-medium">
                    {metric.category}
                  </TableCell>
                  <TableCell className="text-right text-muted-foreground">
                    {metric.before}
                  </TableCell>
                  <TableCell className="text-right font-semibold">
                    {metric.after}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-2">
                      <TrendIcon value={metric.improvementValue} />
                      <span className={getImprovementColor(metric.improvementValue)}>
                        {metric.improvement}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell className="text-center">
                    <div className="flex items-center justify-center gap-2">
                      <StatusIcon status={metric.status} />
                      <Badge
                        variant={
                          metric.status === 'improved'
                            ? 'default'
                            : metric.status === 'declined'
                            ? 'destructive'
                            : 'secondary'
                        }
                        className="text-xs"
                      >
                        {metric.status === 'improved' && '✅ Improved'}
                        {metric.status === 'declined' && '❌ Declined'}
                        {metric.status === 'unchanged' && '➖ Unchanged'}
                      </Badge>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  )
}
