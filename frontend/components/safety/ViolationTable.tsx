import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Skeleton } from '@/components/ui/skeleton'
import { Shield, AlertTriangle, Zap } from 'lucide-react'
import Link from 'next/link'

interface Violation {
  id: string
  trace_id: string
  violation_type: string
  severity: string
  detected_content: string
  redacted_content: string
  detected_at: string
}

interface ViolationTableProps {
  violations: Violation[]
  loading?: boolean
}

const SEVERITY_STYLES = {
  critical: 'bg-red-100 text-red-800 border-red-500 hover:bg-red-100',
  high: 'bg-orange-100 text-orange-800 border-orange-500 hover:bg-orange-100',
  medium: 'bg-yellow-100 text-yellow-800 border-yellow-500 hover:bg-yellow-100'
}

const TYPE_ICONS = {
  pii: Shield,
  toxicity: AlertTriangle,
  injection: Zap,
  prompt_injection: Zap
}

function getRelativeTime(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (diffInSeconds < 60) return `${diffInSeconds}s ago`
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
  return `${Math.floor(diffInSeconds / 86400)}d ago`
}

export function ViolationTable({ violations, loading = false }: ViolationTableProps) {
  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Violations</CardTitle>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[400px] w-full" />
        </CardContent>
      </Card>
    )
  }

  if (!violations || violations.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Violations</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[200px] flex items-center justify-center text-muted-foreground">
            No violations detected - your agents are safe!
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Violations</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="overflow-auto max-h-[500px]">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Type</TableHead>
                <TableHead>Severity</TableHead>
                <TableHead>Redacted Content</TableHead>
                <TableHead>Trace ID</TableHead>
                <TableHead>Time</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {violations.map((violation) => {
                const Icon = TYPE_ICONS[violation.violation_type as keyof typeof TYPE_ICONS] || Shield
                const severityStyle = SEVERITY_STYLES[violation.severity as keyof typeof SEVERITY_STYLES] || SEVERITY_STYLES.medium

                return (
                  <TableRow key={violation.id}>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <Icon className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm capitalize">
                          {violation.violation_type.replace('_', ' ')}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge className={severityStyle}>
                        {violation.severity}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="max-w-md">
                        <p className="text-sm font-mono text-muted-foreground truncate">
                          {violation.redacted_content}
                        </p>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Link
                        href={`/dashboard/traces/${violation.trace_id}`}
                        className="text-sm text-blue-600 hover:underline font-mono"
                      >
                        {violation.trace_id.substring(0, 8)}...
                      </Link>
                    </TableCell>
                    <TableCell>
                      <span className="text-sm text-muted-foreground">
                        {getRelativeTime(violation.detected_at)}
                      </span>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  )
}
