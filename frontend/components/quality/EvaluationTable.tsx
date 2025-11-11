'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import Link from 'next/link'
import { formatDistanceToNow } from 'date-fns'

interface Evaluation {
  id: string
  trace_id: string
  overall_score: number
  evaluator: string
  created_at: string
  accuracy_score: number | null
  relevance_score: number | null
  helpfulness_score: number | null
  coherence_score: number | null
}

interface EvaluationTableProps {
  evaluations: Evaluation[]
  loading?: boolean
}

export function EvaluationTable({ evaluations, loading = false }: EvaluationTableProps) {
  const getScoreBadgeVariant = (score: number) => {
    if (score >= 8) return 'default' // green
    if (score >= 6) return 'secondary' // yellow/neutral
    return 'destructive' // red
  }

  const formatRelativeTime = (dateString: string) => {
    try {
      return formatDistanceToNow(new Date(dateString), { addSuffix: true })
    } catch (error) {
      return dateString
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Evaluations</CardTitle>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="space-y-2">
            {[...Array(5)].map((_, i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        ) : evaluations && evaluations.length > 0 ? (
          <div className="overflow-auto max-h-[400px]">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Trace ID</TableHead>
                  <TableHead className="text-center">Overall Score</TableHead>
                  <TableHead className="text-center">Accuracy</TableHead>
                  <TableHead className="text-center">Relevance</TableHead>
                  <TableHead className="text-center">Helpfulness</TableHead>
                  <TableHead className="text-center">Coherence</TableHead>
                  <TableHead>Evaluator</TableHead>
                  <TableHead>Time</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {evaluations.slice(0, 10).map((evaluation) => (
                  <TableRow key={evaluation.id}>
                    <TableCell>
                      <Link
                        href={`/dashboard/traces/${evaluation.trace_id}`}
                        className="font-mono text-sm text-blue-600 hover:text-blue-800 hover:underline"
                      >
                        {evaluation.trace_id.substring(0, 12)}...
                      </Link>
                    </TableCell>
                    <TableCell className="text-center">
                      <Badge variant={getScoreBadgeVariant(evaluation.overall_score || 0)}>
                        {(evaluation.overall_score || 0).toFixed(1)}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-center text-sm">
                      {evaluation.accuracy_score ? evaluation.accuracy_score.toFixed(1) : '—'}
                    </TableCell>
                    <TableCell className="text-center text-sm">
                      {evaluation.relevance_score ? evaluation.relevance_score.toFixed(1) : '—'}
                    </TableCell>
                    <TableCell className="text-center text-sm">
                      {evaluation.helpfulness_score ? evaluation.helpfulness_score.toFixed(1) : '—'}
                    </TableCell>
                    <TableCell className="text-center text-sm">
                      {evaluation.coherence_score ? evaluation.coherence_score.toFixed(1) : '—'}
                    </TableCell>
                    <TableCell>
                      <span className="text-sm capitalize">{evaluation.evaluator}</span>
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {formatRelativeTime(evaluation.created_at)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        ) : (
          <div className="h-[300px] flex items-center justify-center text-muted-foreground">
            No evaluations yet
          </div>
        )}
      </CardContent>
    </Card>
  )
}
