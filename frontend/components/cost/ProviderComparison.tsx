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
import { TrendingUp, TrendingDown, DollarSign, Activity, AlertCircle } from 'lucide-react';

interface ProviderData {
  provider_name: string;
  total_cost_usd: number;
  request_count: number;
  success_count: number;
  error_count: number;
  error_rate: number;
  p50_latency_ms: number;
  p95_latency_ms: number;
  p99_latency_ms: number;
  avg_latency_ms: number;
  cost_per_request_usd: number;
  cost_per_success_usd: number;
}

interface ProviderComparisonResponse {
  data: ProviderData[];
  meta: {
    range: string;
    total_providers: number;
    total_cost_usd: number;
    total_requests: number;
  };
}

/**
 * ProviderComparison - Multi-provider cost and performance analysis
 *
 * Compares OpenAI, Anthropic, Google, and other AI providers across:
 * - Total cost and cost efficiency
 * - Request volume and success rates
 * - Latency percentiles (P50, P95, P99)
 * - Error rates
 */
export function ProviderComparison() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<ProviderComparisonResponse>({
    queryKey: ['provider-comparison', filters.range],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);

      const res = await fetch(`/api/v1/cost/provider-comparison?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      if (!res.ok) throw new Error('Failed to fetch provider comparison');
      return res.json();
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get performance rating based on latency
  const getPerformanceRating = (p95: number): { label: string; color: string } => {
    if (p95 < 1000) return { label: 'Excellent', color: 'text-green-600' };
    if (p95 < 2000) return { label: 'Good', color: 'text-blue-600' };
    if (p95 < 3000) return { label: 'Fair', color: 'text-yellow-600' };
    return { label: 'Poor', color: 'text-red-600' };
  };

  // Get cost efficiency rating
  const getCostEfficiency = (costPerSuccess: number): { label: string; color: string } => {
    if (costPerSuccess < 0.001) return { label: 'Excellent', color: 'text-green-600' };
    if (costPerSuccess < 0.01) return { label: 'Good', color: 'text-blue-600' };
    if (costPerSuccess < 0.05) return { label: 'Fair', color: 'text-yellow-600' };
    return { label: 'Expensive', color: 'text-red-600' };
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>AI Provider Comparison</CardTitle>
          <CardDescription>Loading provider data...</CardDescription>
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
          <CardTitle>AI Provider Comparison</CardTitle>
          <CardDescription>Cost and performance across providers</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Activity className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Provider Data</p>
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
            <CardTitle>AI Provider Comparison</CardTitle>
            <CardDescription>
              {data?.meta?.total_providers ?? 0} providers • ${data?.meta?.total_cost_usd?.toFixed(2) ?? '0.00'} total • {data?.meta?.total_requests?.toLocaleString() ?? '0'} requests
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
                <TableHead className="w-[140px]">Provider</TableHead>
                <TableHead className="text-right">Total Cost</TableHead>
                <TableHead className="text-right">Requests</TableHead>
                <TableHead className="text-right">Error Rate</TableHead>
                <TableHead className="text-right">P95 Latency</TableHead>
                <TableHead className="text-right">Cost/Success</TableHead>
                <TableHead className="text-center">Performance</TableHead>
                <TableHead className="text-center">Efficiency</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.data.map((provider) => {
                const perfRating = getPerformanceRating(provider.p95_latency_ms);
                const costRating = getCostEfficiency(provider.cost_per_success_usd);

                return (
                  <TableRow key={provider.provider_name}>
                    <TableCell className="font-medium">
                      <div className="flex items-center gap-2">
                        <DollarSign className="h-4 w-4 text-muted-foreground" />
                        {provider.provider_name}
                      </div>
                    </TableCell>
                    <TableCell className="text-right font-medium">
                      ${provider.total_cost_usd.toFixed(2)}
                    </TableCell>
                    <TableCell className="text-right">
                      <div>
                        <div className="font-medium">{provider.request_count.toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground">
                          {provider.success_count.toLocaleString()} success
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <Badge
                        variant={provider.error_rate > 5 ? 'destructive' : provider.error_rate > 1 ? 'default' : 'secondary'}
                      >
                        {provider.error_rate.toFixed(1)}%
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <div>
                        <div className="font-medium">{Math.round(provider.p95_latency_ms)}ms</div>
                        <div className="text-xs text-muted-foreground">
                          P50: {Math.round(provider.p50_latency_ms)}ms
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-right font-mono text-sm">
                      ${provider.cost_per_success_usd.toFixed(4)}
                    </TableCell>
                    <TableCell className="text-center">
                      <span className={`text-xs font-medium ${perfRating.color}`}>
                        {perfRating.label}
                      </span>
                    </TableCell>
                    <TableCell className="text-center">
                      <span className={`text-xs font-medium ${costRating.color}`}>
                        {costRating.label}
                      </span>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-3 gap-4 mt-6">
          <div className="rounded-lg border p-4">
            <div className="flex items-center gap-2 mb-2">
              <DollarSign className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm font-medium">Lowest Cost/Request</span>
            </div>
            {data.data.length > 0 && (
              <div>
                <div className="text-2xl font-bold">
                  ${Math.min(...data.data.map(p => p.cost_per_request_usd).filter(v => v != null)).toFixed(4)}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {data.data.reduce((min, p) =>
                    p.cost_per_request_usd < min.cost_per_request_usd ? p : min
                  ).provider_name}
                </p>
              </div>
            )}
          </div>

          <div className="rounded-lg border p-4">
            <div className="flex items-center gap-2 mb-2">
              <Activity className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm font-medium">Fastest P95</span>
            </div>
            {data.data.length > 0 && (
              <div>
                <div className="text-2xl font-bold">
                  {Math.min(...data.data.map(p => p.p95_latency_ms).filter(v => v != null)).toFixed(0)}ms
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {data.data.reduce((min, p) =>
                    p.p95_latency_ms < min.p95_latency_ms ? p : min
                  ).provider_name}
                </p>
              </div>
            )}
          </div>

          <div className="rounded-lg border p-4">
            <div className="flex items-center gap-2 mb-2">
              <AlertCircle className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm font-medium">Lowest Error Rate</span>
            </div>
            {data.data.length > 0 && (
              <div>
                <div className="text-2xl font-bold">
                  {Math.min(...data.data.map(p => p.error_rate).filter(v => v != null)).toFixed(1)}%
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {data.data.reduce((min, p) =>
                    p.error_rate < min.error_rate ? p : min
                  ).provider_name}
                </p>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
