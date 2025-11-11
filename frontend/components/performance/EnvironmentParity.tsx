"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
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
import { Server, CheckCircle2, AlertTriangle, XCircle } from 'lucide-react';

interface EnvironmentData {
  environment: string;
  request_count: number;
  success_count: number;
  error_count: number;
  error_rate: number;
  p50_latency_ms: number;
  p90_latency_ms: number;
  p95_latency_ms: number;
  p99_latency_ms: number;
  avg_latency_ms: number;
  avg_cost_per_request: number;
  unique_agents: number;
  parity_score: number;
}

interface EnvironmentParityResponse {
  data: EnvironmentData[];
  meta: {
    range: string;
    total_environments: number;
  };
}

/**
 * EnvironmentParity - Compare performance across environments
 *
 * Features:
 * - Performance comparison (production, staging, development)
 * - Parity score (0-100) indicating similarity to baseline
 * - Latency percentiles comparison
 * - Error rate comparison
 * - Identifies performance disparities
 */
export function EnvironmentParity() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<EnvironmentParityResponse>({
    queryKey: ['environment-parity', filters.range],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);

      const res = await fetch(`/api/v1/performance/environment-parity?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      if (!res.ok) throw new Error('Failed to fetch environment parity');
      return res.json();
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get parity status
  const getParityStatus = (score: number): { label: string; icon: React.ReactNode; color: string } => {
    if (score >= 90) return {
      label: 'Excellent',
      icon: <CheckCircle2 className="h-4 w-4 text-green-600" />,
      color: 'text-green-600'
    };
    if (score >= 75) return {
      label: 'Good',
      icon: <CheckCircle2 className="h-4 w-4 text-blue-600" />,
      color: 'text-blue-600'
    };
    if (score >= 60) return {
      label: 'Fair',
      icon: <AlertTriangle className="h-4 w-4 text-yellow-600" />,
      color: 'text-yellow-600'
    };
    return {
      label: 'Poor',
      icon: <XCircle className="h-4 w-4 text-red-600" />,
      color: 'text-red-600'
    };
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Environment Parity Analysis</CardTitle>
          <CardDescription>Loading environment data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[400px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Environment Parity Analysis</CardTitle>
          <CardDescription>Performance comparison across environments</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Server className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Environment Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              No requests found for the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Get baseline (highest volume environment)
  const baseline = data.data[0];

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Environment Parity Analysis</CardTitle>
            <CardDescription>
              {data.meta.total_environments} environments • Baseline: {baseline.environment}
            </CardDescription>
          </div>
          <Badge variant="secondary">{filters.range}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[160px]">Environment</TableHead>
                <TableHead className="text-right">Requests</TableHead>
                <TableHead className="text-right">Error Rate</TableHead>
                <TableHead className="text-right">P90 Latency</TableHead>
                <TableHead className="text-right">P99 Latency</TableHead>
                <TableHead className="text-right">Agents</TableHead>
                <TableHead className="text-center">Parity Score</TableHead>
                <TableHead className="text-center">Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.data.map((env, index) => {
                const parityStatus = getParityStatus(env.parity_score);
                const isBaseline = index === 0;

                return (
                  <TableRow key={env.environment} className={isBaseline ? 'bg-muted/50' : ''}>
                    <TableCell className="font-medium">
                      <div className="flex items-center gap-2">
                        <Server className="h-4 w-4 text-muted-foreground" />
                        <span>{env.environment}</span>
                        {isBaseline && (
                          <Badge variant="outline" className="text-xs">Baseline</Badge>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div>
                        <div className="font-medium">{env.request_count.toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground">
                          {((env.request_count / baseline.request_count) * 100).toFixed(0)}% of baseline
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <Badge
                        variant={env.error_rate > 5 ? 'destructive' : env.error_rate > 1 ? 'default' : 'secondary'}
                      >
                        {env.error_rate.toFixed(1)}%
                      </Badge>
                      {!isBaseline && (
                        <div className="text-xs text-muted-foreground mt-1">
                          {env.error_rate > baseline.error_rate ? '+' : ''}
                          {(env.error_rate - baseline.error_rate).toFixed(1)}pp
                        </div>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <div>
                        <div className="font-medium">{Math.round(env.p90_latency_ms)}ms</div>
                        {!isBaseline && (
                          <div className="text-xs text-muted-foreground">
                            {env.p90_latency_ms > baseline.p90_latency_ms ? '+' : ''}
                            {Math.round(env.p90_latency_ms - baseline.p90_latency_ms)}ms
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div>
                        <div className="font-medium">{Math.round(env.p99_latency_ms)}ms</div>
                        {!isBaseline && (
                          <div className="text-xs text-muted-foreground">
                            {env.p99_latency_ms > baseline.p99_latency_ms ? '+' : ''}
                            {Math.round(env.p99_latency_ms - baseline.p99_latency_ms)}ms
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      {env.unique_agents}
                    </TableCell>
                    <TableCell className="text-center">
                      <div className="flex flex-col items-center gap-1">
                        <span className={`text-lg font-bold ${parityStatus.color}`}>
                          {env.parity_score.toFixed(0)}
                        </span>
                        <span className="text-xs text-muted-foreground">/100</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-center">
                      <div className="flex flex-col items-center gap-1">
                        {parityStatus.icon}
                        <span className={`text-xs font-medium ${parityStatus.color}`}>
                          {parityStatus.label}
                        </span>
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>

        {/* Parity Insights */}
        <div className="mt-6 p-4 rounded-lg bg-muted/50">
          <h4 className="text-sm font-medium mb-2">Parity Score Explanation</h4>
          <div className="text-xs text-muted-foreground space-y-1">
            <p>• <span className="font-medium">100</span> = Identical performance to baseline</p>
            <p>• <span className="font-medium">90-100</span> = Excellent parity (negligible differences)</p>
            <p>• <span className="font-medium">75-89</span> = Good parity (minor differences)</p>
            <p>• <span className="font-medium">60-74</span> = Fair parity (noticeable differences)</p>
            <p>• <span className="font-medium">&lt;60</span> = Poor parity (significant differences)</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
