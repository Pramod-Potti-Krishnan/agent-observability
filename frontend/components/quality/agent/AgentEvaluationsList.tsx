"use client";

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import Link from 'next/link';
import { formatDistanceToNow } from 'date-fns';

interface AgentEvaluation {
  id: string;
  trace_id: string;
  overall_score: number;
  accuracy_score: number | null;
  relevance_score: number | null;
  helpfulness_score: number | null;
  coherence_score: number | null;
  evaluator: string;
  created_at: string;
}

interface AgentEvaluationsListProps {
  evaluations: AgentEvaluation[];
  loading?: boolean;
}

/**
 * AgentEvaluationsList - Table showing recent evaluations for an agent
 *
 * Features:
 * - Recent evaluations list
 * - Rubric scores display
 * - Click-through to trace details
 */
export function AgentEvaluationsList({ evaluations, loading = false }: AgentEvaluationsListProps) {
  const getScoreBadgeVariant = (score: number) => {
    if (score >= 8) return 'default'; // green
    if (score >= 6) return 'secondary'; // yellow/neutral
    return 'destructive'; // red
  };

  const formatRelativeTime = (dateString: string) => {
    try {
      return formatDistanceToNow(new Date(dateString), { addSuffix: true });
    } catch (error) {
      return dateString;
    }
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Evaluations</CardTitle>
          <CardDescription>Loading evaluation data...</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {[...Array(5)].map((_, i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (!evaluations || evaluations.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Evaluations</CardTitle>
          <CardDescription>No evaluations found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center text-muted-foreground">
            <p className="text-sm">No evaluations yet for this agent</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Evaluations</CardTitle>
        <CardDescription>
          Last {evaluations.length} quality assessments for this agent
        </CardDescription>
      </CardHeader>
      <CardContent>
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
              {evaluations.map((evaluation) => (
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
      </CardContent>
    </Card>
  );
}
