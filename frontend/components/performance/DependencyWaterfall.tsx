"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Clock, TrendingUp } from 'lucide-react';
import apiClient from '@/lib/api-client';

interface PhaseBreakdown {
  phase: string;
  avg_latency_ms: number;
  percentage: number;
}

interface DependencyWaterfallResponse {
  data: PhaseBreakdown[];
  meta: {
    range: string;
    agent_id: string | null;
    request_count: number;
    total_avg_latency_ms: number;
  };
}

/**
 * DependencyWaterfall - Breakdown of request execution phases
 *
 * Features:
 * - Shows time spent in each phase (auth, preprocessing, LLM, postprocessing, tools)
 * - Identifies bottlenecks (typically LLM call is 70% of latency)
 * - Displays percentile distribution for each phase
 * - Visual waterfall chart with proportional widths
 */
export function DependencyWaterfall() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<DependencyWaterfallResponse>({
    queryKey: ['dependency-breakdown', filters.range],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);

      const res = await apiClient.get(`/api/v1/performance/dependency-breakdown?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      return res.data;
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  const getPhaseColor = (phase: string): string => {
    switch (phase.toLowerCase()) {
      case 'auth':
        return 'bg-purple-500';
      case 'preprocessing':
        return 'bg-blue-500';
      case 'llm_call':
        return 'bg-orange-500';
      case 'postprocessing':
        return 'bg-green-500';
      case 'tool_use':
        return 'bg-yellow-500';
      default:
        return 'bg-gray-500';
    }
  };

  const getPhaseLabel = (phase: string): string => {
    // The API returns "Authentication", "Preprocessing", etc.
    return phase;
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Request Phase Breakdown</CardTitle>
          <CardDescription>Loading dependency waterfall...</CardDescription>
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
          <CardTitle>Request Phase Breakdown</CardTitle>
          <CardDescription>Time spent in each execution phase</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Clock className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Phase Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              No phase timing data found for the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Sort phases by typical execution order
  const phaseOrder = ['authentication', 'preprocessing', 'llm call', 'postprocessing', 'tool use'];
  const sortedData = [...data.data].sort((a, b) => {
    const aIndex = phaseOrder.indexOf(a.phase.toLowerCase());
    const bIndex = phaseOrder.indexOf(b.phase.toLowerCase());
    return aIndex - bIndex;
  });

  // Find the bottleneck (highest percentage)
  const bottleneck = sortedData.reduce((max, phase) =>
    phase.percentage > max.percentage ? phase : max
  );

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Request Phase Breakdown</CardTitle>
            <CardDescription>
              {data.meta.request_count.toLocaleString()} requests • {data.meta.total_avg_latency_ms.toFixed(0)}ms avg total latency
            </CardDescription>
          </div>
          <Badge variant="secondary">{filters.range}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        {/* Waterfall Visualization */}
        <div className="space-y-6">
          {/* Visual Waterfall Bar */}
          <div className="space-y-2">
            <div className="flex items-center gap-2 mb-3">
              <Clock className="h-4 w-4 text-muted-foreground" />
              <span className="text-sm font-medium">Execution Timeline</span>
            </div>
            <div className="flex w-full h-12 rounded-lg overflow-hidden border">
              {sortedData.map((phase) => (
                <div
                  key={phase.phase}
                  className={`${getPhaseColor(phase.phase)} flex items-center justify-center text-white text-xs font-medium transition-all hover:opacity-80`}
                  style={{ width: `${phase.percentage}%` }}
                  title={`${getPhaseLabel(phase.phase)}: ${phase.avg_latency_ms.toFixed(0)}ms (${phase.percentage.toFixed(1)}%)`}
                >
                  {phase.percentage > 10 && (
                    <span className="px-2">{phase.percentage.toFixed(0)}%</span>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Phase Details Table */}
          <div className="space-y-3">
            {sortedData.map((phase) => {
              const isBottleneck = phase.phase === bottleneck.phase;

              return (
                <div
                  key={phase.phase}
                  className={`p-4 rounded-lg border ${isBottleneck ? 'border-orange-300 bg-orange-50' : 'border-gray-200'}`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-3">
                      <div className={`w-3 h-3 rounded-full ${getPhaseColor(phase.phase)}`}></div>
                      <span className="font-medium">{getPhaseLabel(phase.phase)}</span>
                      {isBottleneck && (
                        <Badge variant="destructive" className="text-xs">
                          <TrendingUp className="h-3 w-3 mr-1" />
                          Bottleneck
                        </Badge>
                      )}
                    </div>
                    <div className="text-right">
                      <div className="text-lg font-bold">{phase.avg_latency_ms.toFixed(0)}ms</div>
                      <div className="text-xs text-muted-foreground">{phase.percentage.toFixed(1)}% of total</div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Summary Insights */}
          <div className="mt-6 p-4 rounded-lg bg-blue-50 border border-blue-200">
            <div className="flex items-start gap-3">
              <TrendingUp className="h-5 w-5 text-blue-600 mt-0.5" />
              <div>
                <div className="font-medium text-blue-900 mb-1">Performance Insight</div>
                <div className="text-sm text-blue-700">
                  {bottleneck.phase.toLowerCase().includes('llm') ? (
                    <>
                      <strong>LLM calls</strong> account for <strong>{bottleneck.percentage.toFixed(1)}%</strong> of total latency.
                      Consider caching, prompt optimization, or faster models to improve performance.
                    </>
                  ) : (
                    <>
                      <strong>{getPhaseLabel(bottleneck.phase)}</strong> is the primary bottleneck at <strong>{bottleneck.percentage.toFixed(1)}%</strong> of total latency.
                      Focus optimization efforts here for maximum impact.
                    </>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
