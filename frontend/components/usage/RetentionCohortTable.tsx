"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { AlertTriangle } from 'lucide-react';

interface CohortCell {
  cohort_month: string;
  month_offset: number;
  retained_users: number;
  retention_pct: number;
}

interface RetentionCohortResponse {
  cohorts: CohortCell[];
  cohort_months: string[];
  max_offset: number;
  meta: {
    range: string;
    total_cohorts: number;
  };
}

/**
 * RetentionCohortTable - User retention analysis by signup cohort
 *
 * Shows user stickiness over time with cohort-based retention metrics.
 * - Rows = Signup cohorts (by month)
 * - Columns = Months since signup (0, 1, 2, 3...)
 * - Color = Retention percentage (green = high, red = low)
 *
 * PRD Tab 2: Chart 2.9 - Retention Cohort Analysis (P0)
 */
export function RetentionCohortTable() {
  const { user, loading: authLoading } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<RetentionCohortResponse>({
    queryKey: ['retention-cohorts', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/retention-cohorts?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 10 * 60 * 1000, // 10 minutes (cohort data changes slowly)
  });

  // Get cell data for specific cohort and offset
  const getCellData = (cohort: string, offset: number): CohortCell | null => {
    return data?.cohorts.find(
      (cell) => cell.cohort_month === cohort && cell.month_offset === offset
    ) || null;
  };

  // Get color based on retention percentage
  const getColorClass = (percentage: number): string => {
    if (percentage >= 70) return 'bg-green-500 text-white';
    if (percentage >= 50) return 'bg-green-300 text-green-900';
    if (percentage >= 30) return 'bg-yellow-300 text-yellow-900';
    if (percentage >= 10) return 'bg-orange-300 text-orange-900';
    return 'bg-red-300 text-red-900';
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>User Retention Cohort Analysis</CardTitle>
          <CardDescription>Loading cohort data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[400px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.cohort_months.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>User Retention Cohort Analysis</CardTitle>
          <CardDescription>Monthly cohort retention tracking</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <AlertTriangle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Cohort Data Available</p>
            <p className="text-xs text-muted-foreground mt-1">
              Insufficient historical data for cohort analysis
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const cohortMonths = data.cohort_months.slice(0, 12); // Show last 12 cohorts
  const maxOffset = Math.min(data.max_offset, 6); // Show up to 6 months retention
  const offsets = Array.from({ length: maxOffset + 1 }, (_, i) => i);

  return (
    <Card>
      <CardHeader>
        <CardTitle>User Retention Cohort Analysis</CardTitle>
        <CardDescription>
          Monthly signup cohorts × retention over time • {cohortMonths.length} cohorts • {filters.range}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-sm">
            <thead>
              <tr>
                <th className="border p-2 text-left text-xs font-medium text-muted-foreground bg-gray-50 sticky left-0 z-10">
                  Cohort Month
                </th>
                {offsets.map((offset) => (
                  <th
                    key={offset}
                    className="border p-2 text-center text-xs font-medium text-muted-foreground bg-gray-50"
                  >
                    Month {offset}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {cohortMonths.map((cohort) => {
                return (
                  <tr key={cohort} className="hover:bg-muted/50">
                    <td className="border p-2 bg-gray-50 sticky left-0 z-10">
                      <div className="font-medium text-xs whitespace-nowrap">
                        {new Date(cohort + '-01').toLocaleDateString('en-US', {
                          year: 'numeric',
                          month: 'short'
                        })}
                      </div>
                    </td>
                    {offsets.map((offset) => {
                      const cell = getCellData(cohort, offset);

                      if (!cell || cell.retained_users === 0) {
                        return (
                          <td key={offset} className="border p-1">
                            <div className="flex items-center justify-center h-12 bg-gray-50 text-gray-400 rounded">
                              —
                            </div>
                          </td>
                        );
                      }

                      const colorClass = getColorClass(cell.retention_pct);

                      return (
                        <td key={offset} className="border p-1">
                          <div
                            className={`flex flex-col items-center justify-center h-12 rounded ${colorClass} cursor-pointer transition-all hover:scale-105`}
                            title={`${cohort} - Month ${offset}: ${cell.retained_users} users (${cell.retention_pct.toFixed(1)}% retention)`}
                          >
                            <span className="font-bold text-sm">
                              {cell.retention_pct.toFixed(0)}%
                            </span>
                            <span className="text-xs opacity-90">
                              ({cell.retained_users})
                            </span>
                          </div>
                        </td>
                      );
                    })}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Legend */}
        <div className="mt-4 flex items-center gap-4 text-xs">
          <span className="text-muted-foreground">Retention:</span>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-green-500 rounded"></div>
              <span>Excellent (70%+)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-green-300 rounded"></div>
              <span>Good (50-70%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-yellow-300 rounded"></div>
              <span>Fair (30-50%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-orange-300 rounded"></div>
              <span>Poor (10-30%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-red-300 rounded"></div>
              <span>Critical (&lt;10%)</span>
            </div>
          </div>
        </div>

        {/* Insights */}
        <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg text-xs">
          <p className="font-medium text-blue-900 mb-1">💡 Retention Insights</p>
          <ul className="text-blue-800 space-y-1 ml-4 list-disc">
            <li>Month 0 = 100% (baseline cohort size)</li>
            <li>Industry benchmark: 30% retention at Month 3, 20% at Month 6</li>
            <li>Click cells to see users in that cohort + retention period</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}
