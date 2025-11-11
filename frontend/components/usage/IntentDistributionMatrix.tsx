"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { AlertTriangle } from 'lucide-react';

interface IntentCell {
  department_id: string;
  intent_category: string;
  request_count: number;
  pct_of_dept_total: number;
}

interface IntentDistributionResponse {
  cells: IntentCell[];
  departments: string[];
  intent_categories: string[];
  meta: {
    range: string;
    total_requests: number;
  };
}

/**
 * IntentDistributionMatrix - Heatmap showing department × intent category usage
 *
 * Features:
 * - Rows = Departments, Columns = Intent categories
 * - Color intensity = Usage percentage
 * - Marginal totals show dept and intent popularity
 * - Click cell → Agents in that dept+intent combination
 *
 * PRD Tab 2: Chart 2.8 - Intent Distribution Matrix (P0)
 */
export function IntentDistributionMatrix() {
  const { user, loading: authLoading } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<IntentDistributionResponse>({
    queryKey: ['intent-distribution', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/intent-distribution?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get cell data for specific department and intent
  const getCellData = (dept: string, intent: string): IntentCell | null => {
    return data?.cells.find(
      (cell) => cell.department_id === dept && cell.intent_category === intent
    ) || null;
  };

  // Get color based on percentage
  const getColorClass = (percentage: number): string => {
    if (percentage === 0) return 'bg-gray-50 text-gray-400';
    if (percentage < 10) return 'bg-blue-100 text-blue-800';
    if (percentage < 25) return 'bg-blue-200 text-blue-900';
    if (percentage < 50) return 'bg-blue-400 text-white';
    return 'bg-blue-600 text-white';
  };

  // Calculate row totals (per department)
  const getRowTotal = (dept: string): number => {
    return data?.cells
      .filter((cell) => cell.department_id === dept)
      .reduce((sum, cell) => sum + cell.request_count, 0) || 0;
  };

  // Calculate column totals (per intent)
  const getColumnTotal = (intent: string): number => {
    return data?.cells
      .filter((cell) => cell.intent_category === intent)
      .reduce((sum, cell) => sum + cell.request_count, 0) || 0;
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Intent Distribution Matrix</CardTitle>
          <CardDescription>Loading distribution data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[400px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.departments.length === 0 || data.intent_categories.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Intent Distribution Matrix</CardTitle>
          <CardDescription>Department × Intent Category</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <AlertTriangle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Intent Data Available</p>
            <p className="text-xs text-muted-foreground mt-1">
              No intent classifications detected in the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const departments = data.departments.slice(0, 10); // Show top 10 departments
  const intents = data.intent_categories;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Intent Distribution Matrix</CardTitle>
        <CardDescription>
          Usage patterns across departments and use cases • {departments.length} departments × {intents.length} intents • {filters.range}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-sm">
            <thead>
              <tr>
                <th className="border p-2 text-left text-xs font-medium text-muted-foreground bg-gray-50 sticky left-0 z-10">
                  Department
                </th>
                {intents.map((intent) => (
                  <th
                    key={intent}
                    className="border p-2 text-center text-xs font-medium text-muted-foreground bg-gray-50"
                  >
                    <div className="capitalize">{intent.replace('_', ' ')}</div>
                  </th>
                ))}
                <th className="border p-2 text-center text-xs font-medium text-muted-foreground bg-gray-50">
                  Total
                </th>
              </tr>
            </thead>
            <tbody>
              {departments.map((dept) => {
                const rowTotal = getRowTotal(dept);

                return (
                  <tr key={dept} className="hover:bg-muted/50">
                    <td className="border p-2 bg-gray-50 sticky left-0 z-10">
                      <div className="font-medium text-xs truncate max-w-[120px]" title={dept}>
                        {dept}
                      </div>
                    </td>
                    {intents.map((intent) => {
                      const cell = getCellData(dept, intent);
                      const count = cell?.request_count || 0;
                      const percentage = cell?.pct_of_dept_total || 0;
                      const colorClass = getColorClass(percentage);

                      return (
                        <td key={intent} className="border p-1">
                          <div
                            className={`flex flex-col items-center justify-center h-16 rounded ${colorClass} cursor-pointer transition-all hover:scale-105`}
                            title={`${dept} - ${intent}: ${count} requests (${percentage.toFixed(1)}% of dept)`}
                          >
                            <span className="font-bold text-sm">
                              {count > 0 ? count.toLocaleString() : '—'}
                            </span>
                            {percentage > 0 && (
                              <span className="text-xs opacity-90">
                                {percentage.toFixed(0)}%
                              </span>
                            )}
                          </div>
                        </td>
                      );
                    })}
                    <td className="border p-2 bg-gray-50 text-center">
                      <div className="font-bold text-sm">
                        {rowTotal.toLocaleString()}
                      </div>
                    </td>
                  </tr>
                );
              })}
              {/* Column totals row */}
              <tr className="bg-gray-50">
                <td className="border p-2 text-xs font-medium sticky left-0 z-10 bg-gray-50">
                  Total
                </td>
                {intents.map((intent) => {
                  const colTotal = getColumnTotal(intent);
                  return (
                    <td key={intent} className="border p-2 text-center">
                      <div className="font-bold text-sm">{colTotal.toLocaleString()}</div>
                    </td>
                  );
                })}
                <td className="border p-2 text-center">
                  <div className="font-bold text-sm">
                    {data.meta.total_requests.toLocaleString()}
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* Legend */}
        <div className="mt-4 flex items-center gap-4 text-xs">
          <span className="text-muted-foreground">Intensity:</span>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-gray-50 border rounded"></div>
              <span>None</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-100 rounded"></div>
              <span>Low (&lt;10%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-200 rounded"></div>
              <span>Medium (10-25%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-400 rounded"></div>
              <span>High (25-50%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-600 rounded"></div>
              <span>Very High (50%+)</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
