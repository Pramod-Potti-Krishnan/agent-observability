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
  ScatterChart,
  Scatter,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  ReferenceLine,
  Cell
} from 'recharts';
import { TrendingUp, DollarSign, Target, AlertCircle } from 'lucide-react';
import Link from 'next/link';

interface CostTradeoffAgent {
  agent_id: string;
  avg_quality: number;
  avg_cost: number;
  total_requests: number;
  efficiency_score: number;
  quadrant: 'high_quality_low_cost' | 'high_quality_high_cost' | 'low_quality_low_cost' | 'low_quality_high_cost';
}

interface CostTradeoffResponse {
  data: CostTradeoffAgent[];
  median_quality: number;
  median_cost: number;
}

/**
 * QualityCostTradeoff - Scatter plot showing quality vs cost efficiency
 *
 * Features:
 * - Scatter plot with agents plotted by quality score (y) vs cost (x)
 * - Color-coded quadrants (green=optimal, blue=premium, yellow=budget, red=inefficient)
 * - Reference lines at median quality/cost to divide quadrants
 * - Time range selector
 * - Hover tooltips with agent details
 * - Click-through to agent detail pages
 * - Summary stats by quadrant
 */
export function QualityCostTradeoff() {
  const { user, loading: authLoading } = useAuth();
  const [range, setRange] = useState('7d');

  const { data, isLoading } = useQuery<CostTradeoffResponse>({
    queryKey: ['quality-cost-tradeoff', range],
    queryFn: async () => {
      const params = new URLSearchParams({ range });
      const response = await apiClient.get(`/api/v1/quality/cost-tradeoff?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get color for quadrant
  const getQuadrantColor = (quadrant: string) => {
    switch (quadrant) {
      case 'high_quality_low_cost':
        return '#10b981'; // green-500 - Optimal
      case 'high_quality_high_cost':
        return '#3b82f6'; // blue-500 - Premium
      case 'low_quality_low_cost':
        return '#f59e0b'; // amber-500 - Budget
      case 'low_quality_high_cost':
        return '#ef4444'; // red-500 - Inefficient
      default:
        return '#6b7280'; // gray-500
    }
  };

  // Get quadrant label
  const getQuadrantLabel = (quadrant: string) => {
    switch (quadrant) {
      case 'high_quality_low_cost':
        return 'Optimal';
      case 'high_quality_high_cost':
        return 'Premium';
      case 'low_quality_low_cost':
        return 'Budget';
      case 'low_quality_high_cost':
        return 'Inefficient';
      default:
        return 'Unknown';
    }
  };

  // Custom tooltip
  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const agent = payload[0].payload;
      return (
        <div className="bg-white p-3 border border-gray-200 rounded-lg shadow-lg">
          <p className="font-mono text-sm font-semibold mb-2">{agent.agent_id}</p>
          <div className="space-y-1 text-xs">
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Quality Score:</span>
              <span className="font-medium">{(agent.avg_quality || 0).toFixed(2)}/10</span>
            </p>
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Avg Cost:</span>
              <span className="font-medium">${(agent.avg_cost || 0).toFixed(4)}</span>
            </p>
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Requests:</span>
              <span className="font-medium">{agent.total_requests || 0}</span>
            </p>
            <p className="flex justify-between gap-4">
              <span className="text-muted-foreground">Efficiency:</span>
              <span className="font-medium">{(agent.efficiency_score || 0).toFixed(1)}</span>
            </p>
            <div className="pt-1 mt-1 border-t">
              <Badge variant="secondary" className="text-xs">
                {getQuadrantLabel(agent.quadrant)}
              </Badge>
            </div>
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
          <CardTitle>Quality vs Cost Analysis</CardTitle>
          <CardDescription>Loading tradeoff data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[450px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Quality vs Cost Analysis</CardTitle>
          <CardDescription>No tradeoff data found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[450px] flex flex-col items-center justify-center text-center">
            <AlertCircle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Cost-Tradeoff Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              Not enough data to analyze quality vs cost tradeoffs
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Calculate quadrant counts
  const quadrantCounts = data.data.reduce((acc, agent) => {
    acc[agent.quadrant] = (acc[agent.quadrant] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Quality vs Cost Analysis</CardTitle>
            <CardDescription>
              Agent efficiency across quality and cost dimensions • {data.data.length} agents • {range}
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
        <ResponsiveContainer width="100%" height={450}>
          <ScatterChart margin={{ top: 20, right: 30, left: 20, bottom: 20 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
            <XAxis
              type="number"
              dataKey="avg_cost"
              name="Average Cost"
              stroke="#666"
              style={{ fontSize: '12px' }}
              label={{ value: 'Average Cost (USD)', position: 'insideBottom', offset: -10, style: { fontSize: '12px' } }}
              tickFormatter={(value) => `$${(value || 0).toFixed(3)}`}
            />
            <YAxis
              type="number"
              dataKey="avg_quality"
              name="Average Quality"
              stroke="#666"
              style={{ fontSize: '12px' }}
              label={{ value: 'Average Quality Score', angle: -90, position: 'insideLeft', style: { fontSize: '12px' } }}
              domain={[0, 10]}
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend
              wrapperStyle={{ fontSize: '12px' }}
              formatter={(value, entry: any) => {
                const quadrant = entry.payload?.quadrant || value;
                return getQuadrantLabel(quadrant);
              }}
            />

            {/* Reference lines at median values to show quadrants */}
            <ReferenceLine
              y={data.median_quality || 5.0}
              stroke="#94a3b8"
              strokeDasharray="5 5"
              label={{ value: `Median Quality: ${(data.median_quality || 5.0).toFixed(1)}`, position: 'right', style: { fontSize: '10px', fill: '#64748b' } }}
            />
            <ReferenceLine
              x={data.median_cost || 0.001}
              stroke="#94a3b8"
              strokeDasharray="5 5"
              label={{ value: `Median Cost: $${(data.median_cost || 0.001).toFixed(3)}`, position: 'top', style: { fontSize: '10px', fill: '#64748b' } }}
            />

            {/* Scatter points colored by quadrant */}
            <Scatter name="Agents" data={data.data} fill="#8884d8">
              {data.data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={getQuadrantColor(entry.quadrant)} />
              ))}
            </Scatter>
          </ScatterChart>
        </ResponsiveContainer>

        {/* Quadrant Summary */}
        <div className="mt-6 grid grid-cols-4 gap-4 border-t pt-4">
          <div className="text-center p-3 bg-green-50 rounded-lg">
            <div className="flex items-center justify-center gap-1 mb-2">
              <TrendingUp className="h-4 w-4 text-green-600" />
              <p className="text-xs font-medium text-green-900">Optimal</p>
            </div>
            <p className="text-2xl font-bold text-green-600">
              {quadrantCounts['high_quality_low_cost'] || 0}
            </p>
            <p className="text-xs text-green-700 mt-1">High Quality, Low Cost</p>
          </div>
          <div className="text-center p-3 bg-blue-50 rounded-lg">
            <div className="flex items-center justify-center gap-1 mb-2">
              <Target className="h-4 w-4 text-blue-600" />
              <p className="text-xs font-medium text-blue-900">Premium</p>
            </div>
            <p className="text-2xl font-bold text-blue-600">
              {quadrantCounts['high_quality_high_cost'] || 0}
            </p>
            <p className="text-xs text-blue-700 mt-1">High Quality, High Cost</p>
          </div>
          <div className="text-center p-3 bg-amber-50 rounded-lg">
            <div className="flex items-center justify-center gap-1 mb-2">
              <DollarSign className="h-4 w-4 text-amber-600" />
              <p className="text-xs font-medium text-amber-900">Budget</p>
            </div>
            <p className="text-2xl font-bold text-amber-600">
              {quadrantCounts['low_quality_low_cost'] || 0}
            </p>
            <p className="text-xs text-amber-700 mt-1">Low Quality, Low Cost</p>
          </div>
          <div className="text-center p-3 bg-red-50 rounded-lg">
            <div className="flex items-center justify-center gap-1 mb-2">
              <AlertCircle className="h-4 w-4 text-red-600" />
              <p className="text-xs font-medium text-red-900">Inefficient</p>
            </div>
            <p className="text-2xl font-bold text-red-600">
              {quadrantCounts['low_quality_high_cost'] || 0}
            </p>
            <p className="text-xs text-red-700 mt-1">Low Quality, High Cost</p>
          </div>
        </div>

        {/* Top Performers */}
        <div className="mt-4 pt-4 border-t">
          <p className="text-sm font-medium mb-3">Most Efficient Agents (Top 5)</p>
          <div className="space-y-2">
            {data.data
              .sort((a, b) => b.efficiency_score - a.efficiency_score)
              .slice(0, 5)
              .map((agent, index) => (
                <Link
                  key={agent.agent_id}
                  href={`/dashboard/performance/agents/${agent.agent_id}`}
                  className="flex items-center justify-between p-2 hover:bg-muted/50 rounded-lg transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-xs text-muted-foreground w-4">#{index + 1}</span>
                    <span className="font-mono text-sm">{agent.agent_id}</span>
                    <Badge variant="secondary" className="text-xs">
                      {getQuadrantLabel(agent.quadrant)}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-4 text-xs">
                    <div className="text-right">
                      <p className="text-muted-foreground">Quality</p>
                      <p className="font-medium">{(agent.avg_quality || 0).toFixed(2)}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-muted-foreground">Cost</p>
                      <p className="font-medium">${(agent.avg_cost || 0).toFixed(4)}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-muted-foreground">Efficiency</p>
                      <p className="font-bold text-green-600">{(agent.efficiency_score || 0).toFixed(1)}</p>
                    </div>
                  </div>
                </Link>
              ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
