"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { AlertTriangle } from 'lucide-react';

interface HeatmapCell {
  agent_id: string;
  violation_type: string;
  count: number;
  severity: 'low' | 'medium' | 'high' | 'critical';
}

interface RiskHeatmapData {
  cells: HeatmapCell[];
  agents: string[];
  violation_types: string[];
}

/**
 * RiskHeatmap - Displays agent vs violation type grid showing risk hot spots
 *
 * Features:
 * - Color-coded cells based on violation count
 * - Hover to see violation details
 * - Click to drill down to agent details
 */
export function RiskHeatmap() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<RiskHeatmapData>({
    queryKey: ['risk-heatmap', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/guardrails/risk-heatmap?time_range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get color based on violation count
  const getCellColor = (count: number): string => {
    if (count === 0) return 'bg-gray-50 text-gray-400';
    if (count <= 2) return 'bg-yellow-100 text-yellow-800';
    if (count <= 5) return 'bg-orange-200 text-orange-900';
    if (count <= 10) return 'bg-red-300 text-red-950';
    return 'bg-red-500 text-white';
  };

  // Get cell data for specific agent and violation type
  const getCellData = (agentId: string, violationType: string): HeatmapCell | null => {
    return data?.cells.find(
      cell => cell.agent_id === agentId && cell.violation_type === violationType
    ) || null;
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Risk Heatmap</CardTitle>
          <CardDescription>Loading risk analysis...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[400px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.agents.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Risk Heatmap</CardTitle>
          <CardDescription>Agent × Violation Type</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <AlertTriangle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Risk Data Available</p>
            <p className="text-xs text-muted-foreground mt-1">
              No violations detected in the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const violationTypes = ['pii', 'toxicity', 'injection'];
  const topAgents = data.agents.slice(0, 10); // Show top 10 agents

  return (
    <Card>
      <CardHeader>
        <CardTitle>Risk Heatmap</CardTitle>
        <CardDescription>
          Violation distribution across agents and types • Top {topAgents.length} agents • {filters.range}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr>
                <th className="border p-2 text-left text-sm font-medium text-muted-foreground bg-gray-50">
                  Agent ID
                </th>
                {violationTypes.map((type) => (
                  <th
                    key={type}
                    className="border p-2 text-center text-sm font-medium text-muted-foreground bg-gray-50"
                  >
                    {type.charAt(0).toUpperCase() + type.slice(1)}
                  </th>
                ))}
                <th className="border p-2 text-center text-sm font-medium text-muted-foreground bg-gray-50">
                  Total
                </th>
              </tr>
            </thead>
            <tbody>
              {topAgents.map((agentId) => {
                const rowTotal = violationTypes.reduce((sum, type) => {
                  const cell = getCellData(agentId, type);
                  return sum + (cell?.count || 0);
                }, 0);

                return (
                  <tr key={agentId} className="hover:bg-muted/50">
                    <td className="border p-2">
                      <div className="flex flex-col">
                        <span className="font-mono text-xs font-medium truncate max-w-[150px]">
                          {agentId}
                        </span>
                      </div>
                    </td>
                    {violationTypes.map((type) => {
                      const cell = getCellData(agentId, type);
                      const count = cell?.count || 0;
                      const colorClass = getCellColor(count);

                      return (
                        <td key={type} className="border p-1">
                          <div
                            className={`flex items-center justify-center h-12 rounded ${colorClass} cursor-pointer transition-all hover:scale-105`}
                            title={`${count} ${type} violations`}
                          >
                            <span className="font-bold text-sm">
                              {count > 0 ? count : '—'}
                            </span>
                          </div>
                        </td>
                      );
                    })}
                    <td className="border p-2 bg-gray-50">
                      <div className="flex items-center justify-center">
                        <Badge variant={rowTotal > 10 ? 'destructive' : 'secondary'}>
                          {rowTotal}
                        </Badge>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Legend */}
        <div className="mt-4 flex items-center gap-4 text-xs">
          <span className="text-muted-foreground">Severity:</span>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-gray-50 border rounded"></div>
              <span>None</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-yellow-100 rounded"></div>
              <span>Low (1-2)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-orange-200 rounded"></div>
              <span>Medium (3-5)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-red-300 rounded"></div>
              <span>High (6-10)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-red-500 rounded"></div>
              <span>Critical (10+)</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
