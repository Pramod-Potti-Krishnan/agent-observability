"use client";

import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
} from 'recharts';
import { TrendingUp, TrendingDown, Minus, AlertCircle } from 'lucide-react';

interface DriftDataPoint {
  timestamp: string;
  avg_score: number;
  eval_count: number;
}

interface DriftTimelineResponse {
  data: DriftDataPoint[];
  overall_trend: 'improving' | 'stable' | 'degrading';
  drift_percentage: number;
}

/**
 * DriftTimelineChart - Time-series visualization of quality score trends and drift
 *
 * Features:
 * - Area chart showing quality scores over time
 * - Detects and highlights quality drift (improving/degrading trends)
 * - Time range selector (1h, 24h, 7d, 30d)
 * - Granularity selector (hourly, daily, weekly)
 * - Reference line at quality threshold (5.0)
 * - Trend indicator badge
 * - Color-coded area (green=above threshold, red=below threshold)
 * - Tooltip with timestamp, score, and evaluation count
 */
export function DriftTimelineChart() {
  const { user, loading: authLoading } = useAuth();
  const [range, setRange] = useState('7d');
  const [granularity, setGranularity] = useState('daily');

  const { data, isLoading } = useQuery<DriftTimelineResponse>({
    queryKey: ['quality-drift-timeline', range, granularity],
    queryFn: async () => {
      const params = new URLSearchParams({ range, granularity });
      const response = await apiClient.get(`/api/v1/quality/drift-timeline?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Format timestamp for display
  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    if (granularity === 'hourly') {
      return date.toLocaleTimeString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    } else if (granularity === 'daily') {
      return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
    } else {
      return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
    }
  };

  // Get trend display
  const getTrendDisplay = (trend: string) => {
    if (trend === 'improving') {
      return {
        icon: <TrendingUp className="h-4 w-4" />,
        color: 'text-green-600',
        bgColor: 'bg-green-50',
        label: 'Improving',
        variant: 'default' as const
      };
    } else if (trend === 'degrading') {
      return {
        icon: <TrendingDown className="h-4 w-4" />,
        color: 'text-red-600',
        bgColor: 'bg-red-50',
        label: 'Degrading',
        variant: 'destructive' as const
      };
    } else {
      return {
        icon: <Minus className="h-4 w-4" />,
        color: 'text-gray-600',
        bgColor: 'bg-gray-50',
        label: 'Stable',
        variant: 'secondary' as const
      };
    }
  };

  // Custom tooltip
  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const dataPoint = payload[0].payload;
      return (
        <div className="bg-white p-3 border border-gray-200 rounded-lg shadow-lg">
          <p className="text-xs text-muted-foreground mb-1">
            {formatTimestamp(dataPoint.timestamp)}
          </p>
          <div className="space-y-1">
            <p className="flex justify-between gap-4">
              <span className="text-xs">Quality Score:</span>
              <span className="text-sm font-bold">{(dataPoint.avg_score || 0).toFixed(2)}/10</span>
            </p>
            <p className="flex justify-between gap-4">
              <span className="text-xs">Evaluations:</span>
              <span className="text-sm font-medium">{dataPoint.eval_count || 0}</span>
            </p>
          </div>
        </div>
      );
    }
    return null;
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Quality Drift Timeline</CardTitle>
          <CardDescription>Loading drift data...</CardDescription>
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
          <CardTitle>Quality Drift Timeline</CardTitle>
          <CardDescription>No drift data found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[400px] flex flex-col items-center justify-center text-center">
            <AlertCircle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Drift Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              Not enough time-series data to show quality drift
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const trend = getTrendDisplay(data.overall_trend);
  const avgScore = data.data.length > 0
    ? data.data.reduce((sum, d) => sum + (d.avg_score || 0), 0) / data.data.length
    : 0;
  const totalEvals = data.data.reduce((sum, d) => sum + (d.eval_count || 0), 0);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-3">
              <CardTitle>Quality Drift Timeline</CardTitle>
              <Badge variant={trend.variant} className="flex items-center gap-1">
                {trend.icon}
                {trend.label}
                {data.drift_percentage !== 0 && (
                  <span className="ml-1">
                    ({data.drift_percentage > 0 ? '+' : ''}{(data.drift_percentage || 0).toFixed(1)}%)
                  </span>
                )}
              </Badge>
            </div>
            <CardDescription>
              Quality score trends over time • {data.data.length} data points • {totalEvals} total evaluations • {range}
            </CardDescription>
          </div>
          <div className="flex gap-2">
            {/* Time Range Selector */}
            <Select value={range} onValueChange={setRange}>
              <SelectTrigger className="w-[120px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="1h">Last Hour</SelectItem>
                <SelectItem value="24h">Last 24h</SelectItem>
                <SelectItem value="7d">Last 7d</SelectItem>
                <SelectItem value="30d">Last 30d</SelectItem>
              </SelectContent>
            </Select>

            {/* Granularity Selector */}
            <Select value={granularity} onValueChange={setGranularity}>
              <SelectTrigger className="w-[120px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="hourly">Hourly</SelectItem>
                <SelectItem value="daily">Daily</SelectItem>
                <SelectItem value="weekly">Weekly</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={400}>
          <AreaChart
            data={data.data}
            margin={{ top: 20, right: 30, left: 20, bottom: 20 }}
          >
            <defs>
              <linearGradient id="qualityGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8} />
                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0.1} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
            <XAxis
              dataKey="timestamp"
              tickFormatter={formatTimestamp}
              stroke="#666"
              style={{ fontSize: '11px' }}
              angle={-45}
              textAnchor="end"
              height={80}
            />
            <YAxis
              stroke="#666"
              style={{ fontSize: '12px' }}
              label={{ value: 'Quality Score', angle: -90, position: 'insideLeft', style: { fontSize: '12px' } }}
              domain={[0, 10]}
              ticks={[0, 2, 4, 6, 8, 10]}
            />
            <Tooltip content={<CustomTooltip />} />

            {/* Reference line at quality threshold (5.0) */}
            <ReferenceLine
              y={5.0}
              stroke="#ef4444"
              strokeDasharray="5 5"
              label={{
                value: 'Failing Threshold (5.0)',
                position: 'right',
                style: { fontSize: '10px', fill: '#ef4444' }
              }}
            />

            {/* Area chart */}
            <Area
              type="monotone"
              dataKey="avg_score"
              stroke="#3b82f6"
              strokeWidth={2}
              fill="url(#qualityGradient)"
              dot={{ fill: '#3b82f6', r: 4 }}
              activeDot={{ r: 6 }}
            />
          </AreaChart>
        </ResponsiveContainer>

        {/* Summary Stats */}
        <div className="mt-6 grid grid-cols-4 gap-4 border-t pt-4">
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">Avg Quality Score</p>
            <p className="text-2xl font-bold text-blue-600">
              {(avgScore || 0).toFixed(2)}
            </p>
          </div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">Total Evaluations</p>
            <p className="text-2xl font-bold">
              {totalEvals || 0}
            </p>
          </div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">Trend Direction</p>
            <div className={`flex items-center justify-center gap-1 ${trend.color}`}>
              {trend.icon}
              <p className="text-xl font-bold">{trend.label}</p>
            </div>
          </div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">Drift Percentage</p>
            <p className={`text-2xl font-bold ${data.drift_percentage > 0 ? 'text-green-600' : data.drift_percentage < 0 ? 'text-red-600' : 'text-gray-600'}`}>
              {data.drift_percentage > 0 ? '+' : ''}{(data.drift_percentage || 0).toFixed(1)}%
            </p>
          </div>
        </div>

        {/* Quality Insights */}
        <div className="mt-4 pt-4 border-t">
          <p className="text-sm font-medium mb-2">Quality Insights</p>
          <div className="space-y-2 text-xs text-muted-foreground">
            {avgScore >= 7.0 ? (
              <p className="flex items-start gap-2">
                <TrendingUp className="h-4 w-4 text-green-600 mt-0.5 flex-shrink-0" />
                <span>Quality is performing well above the threshold. Continue monitoring for consistency.</span>
              </p>
            ) : avgScore >= 5.0 ? (
              <p className="flex items-start gap-2">
                <Minus className="h-4 w-4 text-amber-600 mt-0.5 flex-shrink-0" />
                <span>Quality is hovering near the threshold. Consider investigating agents with lower scores.</span>
              </p>
            ) : (
              <p className="flex items-start gap-2">
                <TrendingDown className="h-4 w-4 text-red-600 mt-0.5 flex-shrink-0" />
                <span>Quality is below the threshold. Immediate attention required to identify and fix failing agents.</span>
              </p>
            )}
            {data.overall_trend === 'degrading' && (
              <p className="flex items-start gap-2">
                <AlertCircle className="h-4 w-4 text-red-600 mt-0.5 flex-shrink-0" />
                <span>Quality is degrading over time. Review recent changes to prompts, models, or configurations.</span>
              </p>
            )}
            {data.overall_trend === 'improving' && (
              <p className="flex items-start gap-2">
                <TrendingUp className="h-4 w-4 text-green-600 mt-0.5 flex-shrink-0" />
                <span>Quality is improving. Recent optimizations are having a positive impact.</span>
              </p>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
