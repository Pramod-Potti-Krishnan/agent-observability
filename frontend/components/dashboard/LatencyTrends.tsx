"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters, useFilterQueryString } from '@/lib/filter-context';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

interface LatencyDataPoint {
  timestamp: string;
  p50_latency_ms: number;
  p95_latency_ms: number;
  p99_latency_ms: number;
  avg_latency_ms: number;
  request_count: number;
}

interface LatencyTrendsResponse {
  data: LatencyDataPoint[];
  meta: {
    granularity: string;
    range: string;
    total_buckets: number;
  };
}

/**
 * LatencyTrends - Multi-line chart showing latency percentiles over time
 *
 * Features:
 * - P50, P95, P99 percentile lines
 * - Configurable granularity (1h, 6h, 1d)
 * - Respects global filter state
 * - Color-coded lines for easy reading
 * - Interactive tooltips with request counts
 */
export function LatencyTrends() {
  const { user } = useAuth();
  const { filters } = useFilters();
  const [granularity, setGranularity] = React.useState('1h');

  const { data, isLoading } = useQuery<LatencyTrendsResponse>({
    queryKey: ['latency-trends', filters.range, granularity, filters.department, filters.environment, filters.version],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);
      params.set('granularity', granularity);
      if (filters.department) params.set('department', filters.department);
      if (filters.environment) params.set('environment', filters.environment);
      if (filters.version) params.set('version', filters.version);

      const res = await fetch(`/api/v1/analytics/latency-trends?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      if (!res.ok) throw new Error('Failed to fetch latency trends');
      return res.json();
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Format timestamp for display
  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    if (granularity === '1h') {
      return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    } else if (granularity === '6h') {
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit' });
    } else {
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
  };

  // Format chart data
  const chartData = data?.data.map(point => ({
    time: formatTimestamp(point.timestamp),
    P50: Math.round(point.p50_latency_ms),
    P95: Math.round(point.p95_latency_ms),
    P99: Math.round(point.p99_latency_ms),
    requests: point.request_count,
  })) || [];

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Latency Trends</CardTitle>
          <CardDescription>Loading latency data...</CardDescription>
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
          <CardTitle>Latency Trends</CardTitle>
          <CardDescription>P50, P95, P99 latency percentiles over time</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">No latency data available for the selected filters</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Latency Trends</CardTitle>
            <CardDescription>
              P50, P95, P99 latency percentiles • {filters.range}
            </CardDescription>
          </div>
          <Select value={granularity} onValueChange={setGranularity}>
            <SelectTrigger className="w-[140px]">
              <SelectValue placeholder="Granularity" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="1h">Hourly</SelectItem>
              <SelectItem value="6h">6 Hours</SelectItem>
              <SelectItem value="1d">Daily</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis
              dataKey="time"
              tick={{ fontSize: 12 }}
              stroke="#6b7280"
            />
            <YAxis
              label={{ value: 'Latency (ms)', angle: -90, position: 'insideLeft' }}
              tick={{ fontSize: 12 }}
              stroke="#6b7280"
            />
            <Tooltip
              contentStyle={{
                backgroundColor: 'white',
                border: '1px solid #e5e7eb',
                borderRadius: '6px',
              }}
              formatter={(value: number, name: string) => {
                if (name === 'requests') return [value, 'Requests'];
                return [`${value}ms`, name];
              }}
            />
            <Legend />
            <Line
              type="monotone"
              dataKey="P50"
              stroke="#10b981"
              strokeWidth={2}
              dot={false}
              name="P50 (Median)"
            />
            <Line
              type="monotone"
              dataKey="P95"
              stroke="#f59e0b"
              strokeWidth={2}
              dot={false}
              name="P95"
            />
            <Line
              type="monotone"
              dataKey="P99"
              stroke="#ef4444"
              strokeWidth={2}
              dot={false}
              name="P99"
            />
          </LineChart>
        </ResponsiveContainer>

        <div className="mt-4 grid grid-cols-3 gap-4 text-sm">
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full bg-green-500" />
            <span className="text-muted-foreground">P50 (Median): Fast responses</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full bg-orange-500" />
            <span className="text-muted-foreground">P95: Most users experience</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full bg-red-500" />
            <span className="text-muted-foreground">P99: Slowest responses</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
