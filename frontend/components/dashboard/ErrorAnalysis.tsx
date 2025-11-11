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
import { AlertCircle } from 'lucide-react';

interface ErrorItem {
  error_message: string;
  error_count: number;
  percentage_of_errors: number;
  affected_agents: number;
  first_seen: string;
  last_seen: string;
}

interface ErrorAnalysisResponse {
  data: ErrorItem[];
  meta: {
    total_errors: number;
    total_requests: number;
    error_rate: number;
    range: string;
  };
}

/**
 * ErrorAnalysis - Table showing top errors with frequency and impact
 *
 * Features:
 * - Shows top N errors by frequency
 * - Displays affected agent counts
 * - Shows first and last occurrence times
 * - Percentage of total errors
 * - Overall error rate indicator
 */
export function ErrorAnalysis() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<ErrorAnalysisResponse>({
    queryKey: ['error-analysis', filters.range, filters.department, filters.environment, filters.version],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);
      params.set('limit', '10');
      if (filters.department) params.set('department', filters.department);
      if (filters.environment) params.set('environment', filters.environment);
      if (filters.version) params.set('version', filters.version);

      const res = await fetch(`/api/v1/analytics/error-analysis?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      if (!res.ok) throw new Error('Failed to fetch error analysis');
      return res.json();
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Format timestamp for display
  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 60) {
      return `${diffMins}m ago`;
    } else if (diffHours < 24) {
      return `${diffHours}h ago`;
    } else if (diffDays < 7) {
      return `${diffDays}d ago`;
    } else {
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
  };

  // Get error rate severity
  const getErrorRateSeverity = (rate: number) => {
    if (rate >= 10) return 'critical';
    if (rate >= 5) return 'warning';
    return 'normal';
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Error Analysis</CardTitle>
          <CardDescription>Loading error data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[300px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Error Analysis</CardTitle>
          <CardDescription>Top errors and their impact</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <AlertCircle className="h-12 w-12 text-green-500 mb-2" />
            <p className="text-sm font-medium">No Errors Detected!</p>
            <p className="text-xs text-muted-foreground mt-1">
              All requests in the selected time range completed successfully
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const errorRateSeverity = getErrorRateSeverity(data.meta.error_rate);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Error Analysis</CardTitle>
            <CardDescription>
              {data.meta.total_errors.toLocaleString()} errors out of {data.meta.total_requests.toLocaleString()} requests
            </CardDescription>
          </div>
          <Badge
            variant={errorRateSeverity === 'critical' ? 'destructive' : errorRateSeverity === 'warning' ? 'default' : 'secondary'}
            className="text-sm"
          >
            {data.meta.error_rate.toFixed(2)}% Error Rate
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[40%]">Error Message</TableHead>
                <TableHead className="text-center">Count</TableHead>
                <TableHead className="text-center">% of Errors</TableHead>
                <TableHead className="text-center">Affected Agents</TableHead>
                <TableHead className="text-right">First / Last Seen</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.data.map((error, index) => (
                <TableRow key={index}>
                  <TableCell className="font-medium">
                    <div className="flex items-start gap-2">
                      <AlertCircle className="h-4 w-4 text-red-500 mt-0.5 flex-shrink-0" />
                      <span className="text-sm">{error.error_message}</span>
                    </div>
                  </TableCell>
                  <TableCell className="text-center">
                    <Badge variant="outline">{error.error_count}</Badge>
                  </TableCell>
                  <TableCell className="text-center">
                    {error.percentage_of_errors.toFixed(1)}%
                  </TableCell>
                  <TableCell className="text-center">
                    {error.affected_agents}
                  </TableCell>
                  <TableCell className="text-right text-xs text-muted-foreground">
                    <div>{formatTimestamp(error.first_seen)}</div>
                    <div>{formatTimestamp(error.last_seen)}</div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {data.data.length === 10 && (
          <p className="mt-4 text-xs text-muted-foreground text-center">
            Showing top 10 errors • More errors may exist
          </p>
        )}
      </CardContent>
    </Card>
  );
}
