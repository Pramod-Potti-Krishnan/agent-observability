"use client";

import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts';

interface DistributionItem {
  score_range: string;
  count: number;
  percentage: number;
  avg_cost_usd: number;
}

interface DistributionResponse {
  data: DistributionItem[];
  total_evaluations: number;
}

/**
 * QualityDistributionChart - Bar chart showing distribution of scores across quality tiers
 *
 * Features:
 * - Visual distribution across 5 quality tiers
 * - Color-coded bars (green=excellent, yellow=fair, red=poor)
 * - Percentage and count labels
 * - Time range selector
 * - Hover tooltips with detailed stats
 */
export function QualityDistributionChart() {
  const { user, loading: authLoading } = useAuth();
  const [range, setRange] = useState('7d');

  const { data, isLoading } = useQuery<DistributionResponse>({
    queryKey: ['quality-distribution', range],
    queryFn: async () => {
      const params = new URLSearchParams({ range });
      const response = await apiClient.get(`/api/v1/quality/distribution?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Color mapping for quality tiers
  const getBarColor = (scoreRange: string) => {
    if (scoreRange === '9.0-10.0') return '#10b981'; // green-500 - Excellent
    if (scoreRange === '7.0-8.9') return '#3b82f6'; // blue-500 - Good
    if (scoreRange === '5.0-6.9') return '#f59e0b'; // amber-500 - Fair
    if (scoreRange === '3.0-4.9') return '#f97316'; // orange-500 - Poor
    return '#ef4444'; // red-500 - Failing
  };

  const getTierLabel = (scoreRange: string) => {
    if (scoreRange === '9.0-10.0') return 'Excellent';
    if (scoreRange === '7.0-8.9') return 'Good';
    if (scoreRange === '5.0-6.9') return 'Fair';
    if (scoreRange === '3.0-4.9') return 'Poor';
    return 'Failing';
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Quality Score Distribution</CardTitle>
          <CardDescription>Loading distribution data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[350px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Quality Score Distribution</CardTitle>
          <CardDescription>No distribution data found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[350px] flex items-center justify-center text-muted-foreground">
            No quality distribution data available
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
            <CardTitle>Quality Score Distribution</CardTitle>
            <CardDescription>
              Distribution across quality tiers • {data.total_evaluations} total evaluations • {range}
            </CardDescription>
          </div>
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
        </div>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={350}>
          <BarChart data={data.data} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
            <XAxis
              dataKey="score_range"
              tickFormatter={getTierLabel}
              stroke="#666"
              style={{ fontSize: '12px' }}
            />
            <YAxis
              stroke="#666"
              style={{ fontSize: '12px' }}
              label={{ value: 'Evaluation Count', angle: -90, position: 'insideLeft', style: { fontSize: '12px' } }}
            />
            <Tooltip
              formatter={(value: number, name: string, props: any) => {
                if (name === 'count') {
                  return [
                    `${value} evaluations (${props.payload.percentage.toFixed(1)}%)`,
                    getTierLabel(props.payload.score_range)
                  ];
                }
                return [value, name];
              }}
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                border: '1px solid #ccc',
                borderRadius: '4px',
                padding: '10px'
              }}
            />
            <Legend
              formatter={(value) => value === 'count' ? 'Evaluations' : value}
            />
            <Bar dataKey="count" name="count" radius={[8, 8, 0, 0]}>
              {data.data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={getBarColor(entry.score_range)} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>

        {/* Summary Stats */}
        <div className="mt-6 grid grid-cols-3 gap-4 border-t pt-4">
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">High Quality (≥7.0)</p>
            <p className="text-2xl font-bold text-green-600">
              {(
                ((data.data.find(d => d.score_range === '9.0-10.0')?.percentage || 0) +
                 (data.data.find(d => d.score_range === '7.0-8.9')?.percentage || 0))
              ).toFixed(1)}%
            </p>
          </div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">Medium Quality (5.0-6.9)</p>
            <p className="text-2xl font-bold text-amber-600">
              {(data.data.find(d => d.score_range === '5.0-6.9')?.percentage || 0).toFixed(1)}%
            </p>
          </div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">Low Quality (&lt;5.0)</p>
            <p className="text-2xl font-bold text-red-600">
              {(
                ((data.data.find(d => d.score_range === '3.0-4.9')?.percentage || 0) +
                 (data.data.find(d => d.score_range === '0.0-2.9')?.percentage || 0))
              ).toFixed(1)}%
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
