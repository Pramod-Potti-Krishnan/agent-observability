"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

interface DepartmentData {
  department_code: string;
  department_name: string;
  request_count: number;
  avg_latency_ms: number;
  error_rate: number;
  total_cost_usd: number;
}

interface DepartmentBreakdownResponse {
  data: DepartmentData[];
  meta: {
    total_departments: number;
    total_requests: number;
  };
}

/**
 * DepartmentBreakdown - Horizontal bar chart showing requests by department
 *
 * Features:
 * - Shows all departments with trace counts
 * - Color-coded bars
 * - Click to filter dashboard to that department
 * - Highlights currently filtered department
 * - Shows percentage of total traffic
 */
export function DepartmentBreakdown() {
  const { user } = useAuth();
  const { filters, setFilters } = useFilters();

  const { data, isLoading } = useQuery<DepartmentBreakdownResponse>({
    queryKey: ['department-breakdown', filters.range, filters.environment, filters.version],
    queryFn: async () => {
      // Build query params (exclude department since we want all departments)
      const params = new URLSearchParams();
      params.set('range', filters.range);
      if (filters.environment) params.set('environment', filters.environment);
      if (filters.version) params.set('version', filters.version);

      const res = await fetch(`/api/v1/metrics/department-breakdown?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      if (!res.ok) throw new Error('Failed to fetch department breakdown');
      return res.json();
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  const handleDepartmentClick = (departmentCode: string) => {
    // Toggle filter: if already selected, clear it; otherwise set it
    if (filters.department === departmentCode) {
      setFilters({ department: null });
    } else {
      setFilters({ department: departmentCode });
    }
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Requests by Department</CardTitle>
          <CardDescription>Distribution of agent requests across departments</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {[1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} className="h-10 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Requests by Department</CardTitle>
          <CardDescription>Distribution of agent requests across departments</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">No department data available</p>
        </CardContent>
      </Card>
    );
  }

  const maxRequests = Math.max(...data.data.map(d => d.request_count));
  const totalRequests = data.meta.total_requests;

  // Color palette for departments
  const colors = [
    'bg-blue-500',
    'bg-green-500',
    'bg-purple-500',
    'bg-orange-500',
    'bg-pink-500',
    'bg-teal-500',
    'bg-indigo-500',
    'bg-red-500',
    'bg-yellow-500',
    'bg-cyan-500',
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Requests by Department</CardTitle>
        <CardDescription>
          {filters.environment || filters.version
            ? `Filtered by ${[filters.environment, filters.version].filter(Boolean).join(' • ')}`
            : `All departments - ${filters.range}`}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {data.data.map((dept, index) => {
            const percentage = (dept.request_count / totalRequests) * 100;
            const barWidth = (dept.request_count / maxRequests) * 100;
            const isSelected = filters.department === dept.department_code;
            const colorClass = colors[index % colors.length];

            return (
              <button
                key={dept.department_code}
                onClick={() => handleDepartmentClick(dept.department_code)}
                className={`w-full text-left transition-all hover:bg-gray-50 rounded-lg p-2 ${
                  isSelected ? 'ring-2 ring-blue-500 bg-blue-50' : ''
                }`}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium">{dept.department_name}</span>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground">
                    <span>{dept.request_count.toLocaleString()} requests</span>
                    <span className="font-medium">{percentage.toFixed(1)}%</span>
                  </div>
                </div>
                <div className="relative h-6 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className={`absolute inset-y-0 left-0 ${colorClass} transition-all`}
                    style={{ width: `${barWidth}%` }}
                  />
                  <div className="absolute inset-0 flex items-center px-3 text-xs">
                    <span className="text-gray-700 font-medium">
                      Avg: {Math.round(dept.avg_latency_ms)}ms • Errors: {dept.error_rate.toFixed(1)}%
                    </span>
                  </div>
                </div>
              </button>
            );
          })}
        </div>

        <div className="mt-4 pt-4 border-t text-xs text-muted-foreground">
          <p>
            Click a department to filter the dashboard. Total: {totalRequests.toLocaleString()} requests across{' '}
            {data.meta.total_departments} departments
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
