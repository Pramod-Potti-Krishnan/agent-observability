"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Activity } from 'lucide-react';
import apiClient from '@/lib/api-client';

interface PercentileData {
  p50: number;
  p75: number;
  p90: number;
  p95: number;
  p99: number;
}

interface HeatmapDataPoint {
  timestamp: string;
  percentiles: PercentileData;
  request_count: number;
}

interface LatencyHeatmapResponse {
  data: HeatmapDataPoint[];
  meta: {
    range: string;
    granularity: string;
    buckets: number;
  };
}

/**
 * LatencyHeatmap - Time-series heatmap showing P50-P99 distribution
 *
 * Features:
 * - Shows latency percentiles over time
 * - Color intensity indicates latency severity
 * - Identifies performance regression periods
 * - Tooltip shows exact values
 */
export function LatencyHeatmap() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const granularity = filters.range === '1h' || filters.range === '24h' ? 'hourly' : 'daily';

  const { data, isLoading } = useQuery<LatencyHeatmapResponse>({
    queryKey: ['latency-heatmap', filters.range, granularity],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);
      params.set('granularity', granularity);

      const res = await apiClient.get(`/api/v1/performance/latency-heatmap?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      return res.data;
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  const getLatencyColor = (value: number): string => {
    if (value < 500) return 'bg-green-500';
    if (value < 1000) return 'bg-blue-500';
    if (value < 1500) return 'bg-yellow-500';
    if (value < 2000) return 'bg-orange-500';
    return 'bg-red-500';
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Latency Percentile Heatmap</CardTitle>
          <CardDescription>Loading heatmap data...</CardDescription>
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
          <CardTitle>Latency Percentile Heatmap</CardTitle>
          <CardDescription>P50-P99 latency distribution over time</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Activity className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Heatmap Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              No latency data found for the selected time range
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
            <CardTitle>Latency Percentile Heatmap</CardTitle>
            <CardDescription>
              {data.meta.buckets} time buckets • {data.meta.granularity} granularity
            </CardDescription>
          </div>
          <Badge variant="secondary">{filters.range}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        {/* Simplified Heatmap View - showing percentiles as rows */}
        <div className="space-y-4">
          <div className="grid grid-cols-[100px_1fr] gap-4">
            <div className="text-sm font-medium text-muted-foreground space-y-4 pt-4">
              <div className="h-8 flex items-center">P50</div>
              <div className="h-8 flex items-center">P75</div>
              <div className="h-8 flex items-center">P90</div>
              <div className="h-8 flex items-center">P95</div>
              <div className="h-8 flex items-center">P99</div>
            </div>

            <div className="space-y-4">
              {/* P50 Row */}
              <div className="flex gap-1">
                {data.data.map((point, idx) => (
                  <div
                    key={`p50-${idx}`}
                    className={`h-8 flex-1 rounded ${getLatencyColor(point.percentiles.p50)}`}
                    title={`${new Date(point.timestamp).toLocaleString()}\nP50: ${point.percentiles.p50}ms`}
                  />
                ))}
              </div>

              {/* P75 Row */}
              <div className="flex gap-1">
                {data.data.map((point, idx) => (
                  <div
                    key={`p75-${idx}`}
                    className={`h-8 flex-1 rounded ${getLatencyColor(point.percentiles.p75)}`}
                    title={`${new Date(point.timestamp).toLocaleString()}\nP75: ${point.percentiles.p75}ms`}
                  />
                ))}
              </div>

              {/* P90 Row */}
              <div className="flex gap-1">
                {data.data.map((point, idx) => (
                  <div
                    key={`p90-${idx}`}
                    className={`h-8 flex-1 rounded ${getLatencyColor(point.percentiles.p90)}`}
                    title={`${new Date(point.timestamp).toLocaleString()}\nP90: ${point.percentiles.p90}ms`}
                  />
                ))}
              </div>

              {/* P95 Row */}
              <div className="flex gap-1">
                {data.data.map((point, idx) => (
                  <div
                    key={`p95-${idx}`}
                    className={`h-8 flex-1 rounded ${getLatencyColor(point.percentiles.p95)}`}
                    title={`${new Date(point.timestamp).toLocaleString()}\nP95: ${point.percentiles.p95}ms`}
                  />
                ))}
              </div>

              {/* P99 Row */}
              <div className="flex gap-1">
                {data.data.map((point, idx) => (
                  <div
                    key={`p99-${idx}`}
                    className={`h-8 flex-1 rounded ${getLatencyColor(point.percentiles.p99)}`}
                    title={`${new Date(point.timestamp).toLocaleString()}\nP99: ${point.percentiles.p99}ms`}
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Legend */}
          <div className="flex items-center justify-center gap-4 pt-4 border-t">
            <span className="text-xs text-muted-foreground">Latency:</span>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-green-500"></div>
              <span className="text-xs">&lt;500ms</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-blue-500"></div>
              <span className="text-xs">500-1000ms</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-yellow-500"></div>
              <span className="text-xs">1000-1500ms</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-orange-500"></div>
              <span className="text-xs">1500-2000ms</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-red-500"></div>
              <span className="text-xs">&gt;2000ms</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
