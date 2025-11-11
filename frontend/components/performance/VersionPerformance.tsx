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
import { GitBranch, TrendingUp, TrendingDown, Minus, Sparkles } from 'lucide-react';

interface VersionData {
  version: string;
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
  first_seen: string;
  last_seen: string;
  performance_trend: 'new' | 'improving' | 'degrading' | 'stable';
  latency_change_pct: number | null;
  error_rate_change_pct: number | null;
}

interface VersionPerformanceResponse {
  data: VersionData[];
  meta: {
    range: string;
    total_versions: number;
  };
}

/**
 * VersionPerformance - Compare performance across agent versions
 *
 * Features:
 * - Performance metrics by version
 * - Trend indicators (improving, degrading, stable, new)
 * - Change percentages vs previous period
 * - Latency and error rate comparisons
 */
export function VersionPerformance() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<VersionPerformanceResponse>({
    queryKey: ['version-comparison', filters.range],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);

      const res = await fetch(`/api/v1/performance/version-comparison?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      if (!res.ok) throw new Error('Failed to fetch version comparison');
      return res.json();
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get trend indicator
  const getTrendIndicator = (trend: string): { icon: React.ReactNode; label: string; color: string } => {
    switch (trend) {
      case 'improving':
        return {
          icon: <TrendingDown className="h-4 w-4" />,
          label: 'Improving',
          color: 'text-green-600'
        };
      case 'degrading':
        return {
          icon: <TrendingUp className="h-4 w-4" />,
          label: 'Degrading',
          color: 'text-red-600'
        };
      case 'stable':
        return {
          icon: <Minus className="h-4 w-4" />,
          label: 'Stable',
          color: 'text-blue-600'
        };
      case 'new':
        return {
          icon: <Sparkles className="h-4 w-4" />,
          label: 'New',
          color: 'text-purple-600'
        };
      default:
        return {
          icon: <Minus className="h-4 w-4" />,
          label: 'Unknown',
          color: 'text-muted-foreground'
        };
    }
  };

  // Format timestamp
  const formatTimestamp = (timestamp: string) => {
    return new Date(timestamp).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Version Performance Comparison</CardTitle>
          <CardDescription>Loading version data...</CardDescription>
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
          <CardTitle>Version Performance Comparison</CardTitle>
          <CardDescription>Performance metrics across versions</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <GitBranch className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Version Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              No requests found for the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Version Performance Comparison</CardTitle>
            <CardDescription>
              {data.meta.total_versions} versions tracked • {filters.range}
            </CardDescription>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[180px]">Version</TableHead>
                <TableHead className="text-right">Requests</TableHead>
                <TableHead className="text-right">Error Rate</TableHead>
                <TableHead className="text-right">P90 Latency</TableHead>
                <TableHead className="text-right">P99 Latency</TableHead>
                <TableHead className="text-center">Trend</TableHead>
                <TableHead className="text-right">Latency Δ</TableHead>
                <TableHead className="text-right">Error Δ</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.data.map((version) => {
                const trendInfo = getTrendIndicator(version.performance_trend);

                return (
                  <TableRow key={version.version}>
                    <TableCell className="font-medium">
                      <div className="flex items-center gap-2">
                        <GitBranch className="h-4 w-4 text-muted-foreground" />
                        <div>
                          <div className="font-mono text-sm">{version.version}</div>
                          <div className="text-xs text-muted-foreground">
                            {formatTimestamp(version.first_seen)} - {formatTimestamp(version.last_seen)}
                          </div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div>
                        <div className="font-medium">{version.request_count.toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground">
                          {version.unique_agents} agents
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <Badge
                        variant={version.error_rate > 5 ? 'destructive' : version.error_rate > 1 ? 'default' : 'secondary'}
                      >
                        {version.error_rate.toFixed(1)}%
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <div>
                        <div className="font-medium">{Math.round(version.p90_latency_ms)}ms</div>
                        <div className="text-xs text-muted-foreground">
                          P50: {Math.round(version.p50_latency_ms)}ms
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="font-medium">{Math.round(version.p99_latency_ms)}ms</div>
                    </TableCell>
                    <TableCell className="text-center">
                      <div className="flex flex-col items-center gap-1">
                        <div className={trendInfo.color}>
                          {trendInfo.icon}
                        </div>
                        <span className={`text-xs font-medium ${trendInfo.color}`}>
                          {trendInfo.label}
                        </span>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      {version.latency_change_pct !== null ? (
                        <div className="flex items-center justify-end gap-1">
                          {version.latency_change_pct > 0 ? (
                            <TrendingUp className="h-3 w-3 text-red-500" />
                          ) : version.latency_change_pct < 0 ? (
                            <TrendingDown className="h-3 w-3 text-green-500" />
                          ) : null}
                          <span className={version.latency_change_pct > 0 ? 'text-red-500' : version.latency_change_pct < 0 ? 'text-green-500' : 'text-muted-foreground'}>
                            {version.latency_change_pct > 0 ? '+' : ''}{version.latency_change_pct.toFixed(1)}%
                          </span>
                        </div>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      {version.error_rate_change_pct !== null ? (
                        <div className="flex items-center justify-end gap-1">
                          {version.error_rate_change_pct > 0 ? (
                            <TrendingUp className="h-3 w-3 text-red-500" />
                          ) : version.error_rate_change_pct < 0 ? (
                            <TrendingDown className="h-3 w-3 text-green-500" />
                          ) : null}
                          <span className={version.error_rate_change_pct > 0 ? 'text-red-500' : version.error_rate_change_pct < 0 ? 'text-green-500' : 'text-muted-foreground'}>
                            {version.error_rate_change_pct > 0 ? '+' : ''}{version.error_rate_change_pct.toFixed(1)}%
                          </span>
                        </div>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>

        {/* Legend */}
        <div className="mt-6 grid grid-cols-2 gap-4">
          <div className="p-4 rounded-lg bg-muted/50">
            <h4 className="text-sm font-medium mb-2">Performance Trends</h4>
            <div className="space-y-2 text-xs">
              <div className="flex items-center gap-2">
                <TrendingDown className="h-3 w-3 text-green-600" />
                <span><span className="font-medium">Improving:</span> P90 latency decreased by &gt;10%</span>
              </div>
              <div className="flex items-center gap-2">
                <TrendingUp className="h-3 w-3 text-red-600" />
                <span><span className="font-medium">Degrading:</span> P90 latency increased by &gt;10%</span>
              </div>
              <div className="flex items-center gap-2">
                <Minus className="h-3 w-3 text-blue-600" />
                <span><span className="font-medium">Stable:</span> P90 latency changed by &lt;10%</span>
              </div>
              <div className="flex items-center gap-2">
                <Sparkles className="h-3 w-3 text-purple-600" />
                <span><span className="font-medium">New:</span> First time seen in this period</span>
              </div>
            </div>
          </div>

          <div className="p-4 rounded-lg bg-muted/50">
            <h4 className="text-sm font-medium mb-2">Change Indicators</h4>
            <div className="space-y-2 text-xs text-muted-foreground">
              <p>• <span className="font-medium">Latency Δ:</span> P90 latency change vs previous period</p>
              <p>• <span className="font-medium">Error Δ:</span> Error rate change vs previous period</p>
              <p>• <span className="text-green-600">Green</span> = Improvement</p>
              <p>• <span className="text-red-600">Red</span> = Regression</p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
