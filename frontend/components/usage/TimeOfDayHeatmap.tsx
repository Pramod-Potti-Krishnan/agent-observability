"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { AlertTriangle } from 'lucide-react';

interface HeatmapCell {
  hour_of_day: number;
  day_of_week: number;
  request_count_avg: number;
  percentile_rank: number;
}

interface TimeOfDayHeatmapResponse {
  cells: HeatmapCell[];
  max_requests: number;
  meta: {
    range: string;
    total_requests: number;
  };
}

/**
 * TimeOfDayHeatmap - 24×7 usage pattern visualization
 *
 * Shows peak usage patterns by hour and day for capacity planning.
 * - Rows = Hours (0-23)
 * - Columns = Days (Mon-Sun)
 * - Color = Request intensity
 *
 * PRD Tab 2: Chart 2.16 - Time-of-Day Usage Heatmap (P1)
 */
export function TimeOfDayHeatmap() {
  const { user, loading: authLoading } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<TimeOfDayHeatmapResponse>({
    queryKey: ['time-of-day-heatmap', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/time-of-day-heatmap?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 10 * 60 * 1000,
  });

  // Get cell data for specific hour and day
  const getCellData = (hour: number, day: number): HeatmapCell | null => {
    return data?.cells.find(
      (cell) => cell.hour_of_day === hour && cell.day_of_week === day
    ) || null;
  };

  // Get color based on percentile rank
  const getColorClass = (percentile: number): string => {
    if (percentile >= 90) return 'bg-blue-600 text-white';
    if (percentile >= 75) return 'bg-blue-500 text-white';
    if (percentile >= 50) return 'bg-blue-300 text-blue-900';
    if (percentile >= 25) return 'bg-blue-100 text-blue-800';
    return 'bg-gray-50 text-gray-600';
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Time-of-Day Usage Heatmap</CardTitle>
          <CardDescription>Loading heatmap data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[500px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.cells.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Time-of-Day Usage Heatmap</CardTitle>
          <CardDescription>Peak usage patterns for capacity planning</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <AlertTriangle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Heatmap Data Available</p>
            <p className="text-xs text-muted-foreground mt-1">
              Insufficient data for time-of-day analysis
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const hours = Array.from({ length: 24 }, (_, i) => i);
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Time-of-Day Usage Heatmap</CardTitle>
        <CardDescription>
          Average request volume by hour and day • {filters.range}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-xs">
            <thead>
              <tr>
                <th className="border p-2 text-left font-medium text-muted-foreground bg-gray-50 sticky left-0 z-10">
                  Hour
                </th>
                {days.map((day, idx) => (
                  <th
                    key={idx}
                    className="border p-2 text-center font-medium text-muted-foreground bg-gray-50"
                  >
                    {day}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {hours.map((hour) => {
                return (
                  <tr key={hour} className="hover:bg-muted/50">
                    <td className="border p-2 bg-gray-50 sticky left-0 z-10 font-medium">
                      {hour.toString().padStart(2, '0')}:00
                    </td>
                    {days.map((_, dayIdx) => {
                      const cell = getCellData(hour, dayIdx);

                      if (!cell || cell.request_count_avg === 0) {
                        return (
                          <td key={dayIdx} className="border p-1">
                            <div className="flex items-center justify-center h-8 bg-gray-50 text-gray-400">
                              —
                            </div>
                          </td>
                        );
                      }

                      const colorClass = getColorClass(cell.percentile_rank);

                      return (
                        <td key={dayIdx} className="border p-1">
                          <div
                            className={`flex items-center justify-center h-8 rounded ${colorClass} cursor-pointer transition-all hover:scale-105`}
                            title={`${days[dayIdx]} ${hour}:00 - Avg: ${cell.request_count_avg.toFixed(0)} requests (${cell.percentile_rank.toFixed(0)}th percentile)`}
                          >
                            <span className="font-bold text-xs">
                              {cell.request_count_avg >= 1000
                                ? `${(cell.request_count_avg / 1000).toFixed(1)}k`
                                : cell.request_count_avg.toFixed(0)}
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
          <span className="text-muted-foreground">Intensity:</span>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-gray-50 border rounded"></div>
              <span>Minimal (&lt;25%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-100 rounded"></div>
              <span>Low (25-50%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-300 rounded"></div>
              <span>Medium (50-75%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-500 rounded"></div>
              <span>High (75-90%)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-4 h-4 bg-blue-600 rounded"></div>
              <span>Peak (90%+)</span>
            </div>
          </div>
        </div>

        {/* Insights */}
        <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg text-xs">
          <p className="font-medium text-blue-900 mb-1">📊 Peak Usage Insights</p>
          <ul className="text-blue-800 space-y-1 ml-4 list-disc">
            <li>Peak hours typically appear darker (blue) - plan capacity accordingly</li>
            <li>Weekends may show different patterns than weekdays</li>
            <li>Use this data to schedule maintenance during low-traffic periods</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}
