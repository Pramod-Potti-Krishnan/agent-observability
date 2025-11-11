"use client";

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  ReferenceLine
} from 'recharts';
import { format } from 'date-fns';

interface TimelineDataPoint {
  timestamp: string;
  avg_score: number;
  baseline_score: number;
  drift_percentage: number;
  evaluation_count: number;
  alert_triggered: boolean;
}

interface AgentQualityTimelineProps {
  data: TimelineDataPoint[];
  loading?: boolean;
}

/**
 * AgentQualityTimeline - Timeline chart showing quality trend for a single agent
 *
 * Features:
 * - Line chart with quality score over time
 * - Baseline reference line
 * - Drift alerts visualization
 */
export function AgentQualityTimeline({ data, loading = false }: AgentQualityTimelineProps) {
  // Custom tooltip
  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const point = payload[0].payload;
      return (
        <div className="bg-white p-3 border border-gray-200 rounded-lg shadow-lg">
          <p className="text-xs font-semibold mb-2">
            {format(new Date(point.timestamp), 'MMM dd, yyyy HH:mm')}
          </p>
          <div className="space-y-1 text-xs">
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Quality Score:</span>
              <span className="font-medium">{(point.avg_score || 0).toFixed(2)}/10</span>
            </p>
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Baseline:</span>
              <span className="font-medium">{(point.baseline_score || 0).toFixed(2)}</span>
            </p>
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Drift:</span>
              <span className={`font-medium ${Math.abs(point.drift_percentage) >= 10 ? 'text-red-600' : ''}`}>
                {(point.drift_percentage || 0).toFixed(1)}%
              </span>
            </p>
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Evaluations:</span>
              <span className="font-medium">{point.evaluation_count || 0}</span>
            </p>
          </div>
        </div>
      );
    }
    return null;
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Quality Timeline</CardTitle>
          <CardDescription>Loading timeline data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[350px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Quality Timeline</CardTitle>
          <CardDescription>No timeline data available</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[350px] flex items-center justify-center text-muted-foreground">
            <p className="text-sm">No quality data to display</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const baseline = data[0]?.baseline_score || 5.0;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Quality Timeline</CardTitle>
        <CardDescription>
          Quality score trend over time • {data.length} data points
        </CardDescription>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={350}>
          <LineChart data={data} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
            <XAxis
              dataKey="timestamp"
              tickFormatter={(value) => format(new Date(value), 'MM/dd')}
              stroke="#666"
              style={{ fontSize: '12px' }}
            />
            <YAxis
              stroke="#666"
              style={{ fontSize: '12px' }}
              domain={[0, 10]}
              label={{ value: 'Quality Score', angle: -90, position: 'insideLeft', style: { fontSize: '12px' } }}
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend wrapperStyle={{ fontSize: '12px' }} />
            <ReferenceLine
              y={baseline}
              stroke="#94a3b8"
              strokeDasharray="5 5"
              label={{ value: `Baseline: ${baseline.toFixed(1)}`, position: 'right', style: { fontSize: '10px', fill: '#64748b' } }}
            />
            <Line
              type="monotone"
              dataKey="avg_score"
              stroke="#3b82f6"
              strokeWidth={2}
              dot={{ fill: '#3b82f6', r: 4 }}
              activeDot={{ r: 6 }}
              name="Quality Score"
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}
