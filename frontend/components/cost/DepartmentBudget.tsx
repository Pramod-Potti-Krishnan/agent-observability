"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { TrendingUp, TrendingDown, Building2, AlertTriangle } from 'lucide-react';

interface DepartmentBudgetData {
  budget_id: string;
  department_id: string;
  budget_period: string;
  period_start_date: string;
  period_end_date: string;
  allocated_budget_usd: number;
  spent_to_date_usd: number;
  remaining_budget_usd: number;
  budget_consumed_pct: number;
  burn_rate_daily_usd: number | null;
  days_until_depletion: number | null;
  alert_status: 'green' | 'yellow' | 'red';
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

interface DepartmentBudgetResponse {
  data: DepartmentBudgetData[];
  meta: {
    total_budgets: number;
    total_allocated: number;
    total_spent: number;
    overall_consumption_pct: number;
    budgets_by_status: {
      green: number;
      yellow: number;
      red: number;
    };
  };
}

/**
 * DepartmentBudget - Department cost tracking with budget monitoring
 *
 * Features:
 * - Cost breakdown by department
 * - Budget tracking and alerts
 * - Trend analysis (vs previous period)
 * - Top cost agents per department
 */
export function DepartmentBudget() {
  const { user, loading: authLoading } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<DepartmentBudgetResponse>({
    queryKey: ['department-budgets'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/cost/department-budgets');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Helper function to generate department display name from UUID
  const getDepartmentName = (departmentId: string): string => {
    // For MVP, use first 8 chars of UUID as display name
    // In production, this would come from a departments lookup table
    return `Dept-${departmentId.slice(0, 8).toUpperCase()}`;
  };

  // Get badge variant based on alert status
  const getStatusBadge = (status: 'green' | 'yellow' | 'red'): { label: string; variant: 'default' | 'secondary' | 'destructive' } => {
    if (status === 'red') return { label: 'Critical', variant: 'destructive' };
    if (status === 'yellow') return { label: 'Warning', variant: 'default' };
    return { label: 'Healthy', variant: 'secondary' };
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Department Budget Tracking</CardTitle>
          <CardDescription>Loading department data...</CardDescription>
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
          <CardTitle>Department Budget Tracking</CardTitle>
          <CardDescription>Cost breakdown by department</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Building2 className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Department Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              No costs found for the selected time range
            </p>
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
            <CardTitle>Department Budget Dashboard</CardTitle>
            <CardDescription>
              {data?.meta?.total_budgets ?? 0} departments • ${data?.meta?.total_spent?.toFixed(2) ?? '0.00'} spent / ${data?.meta?.total_allocated?.toFixed(2) ?? '0.00'} allocated
              {' • '}
              <span className="font-medium">{data?.meta?.overall_consumption_pct?.toFixed(1) ?? '0.0'}% consumed</span>
            </CardDescription>
          </div>
          {data?.meta?.budgets_by_status && (
            <div className="flex gap-2">
              <Badge variant="secondary">{data?.meta?.budgets_by_status?.green || 0} Green</Badge>
              <Badge variant="default">{data?.meta?.budgets_by_status?.yellow || 0} Yellow</Badge>
              <Badge variant="destructive">{data?.meta?.budgets_by_status?.red || 0} Red</Badge>
            </div>
          )}
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {data.data.map((budget) => {
            const statusBadge = getStatusBadge(budget.alert_status);
            const deptName = getDepartmentName(budget.department_id);

            return (
              <div key={budget.budget_id} className={`rounded-lg border-2 p-5 transition-all hover:shadow-md ${
                budget.alert_status === 'red' ? 'border-red-300 bg-red-50/50' :
                budget.alert_status === 'yellow' ? 'border-yellow-300 bg-yellow-50/50' :
                'border-green-300 bg-green-50/50'
              }`}>
                {/* Department Header */}
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg ${
                      budget.alert_status === 'red' ? 'bg-red-100' :
                      budget.alert_status === 'yellow' ? 'bg-yellow-100' :
                      'bg-green-100'
                    }`}>
                      <Building2 className={`h-5 w-5 ${
                        budget.alert_status === 'red' ? 'text-red-600' :
                        budget.alert_status === 'yellow' ? 'text-yellow-600' :
                        'text-green-600'
                      }`} />
                    </div>
                    <div>
                      <h3 className="font-bold text-lg">{deptName}</h3>
                      <p className="text-xs text-muted-foreground">{budget.budget_period} budget</p>
                    </div>
                  </div>
                  <Badge variant={statusBadge.variant}>{statusBadge.label}</Badge>
                </div>

                {/* Budget Stats */}
                <div className="space-y-3">
                  <div className="flex items-baseline justify-between">
                    <span className="text-sm text-muted-foreground">Spent</span>
                    <span className="text-2xl font-bold">${budget.spent_to_date_usd.toFixed(2)}</span>
                  </div>

                  <Progress
                    value={Math.min(budget.budget_consumed_pct, 100)}
                    className={`h-3 ${
                      budget.alert_status === 'red' ? '[&>div]:bg-red-500' :
                      budget.alert_status === 'yellow' ? '[&>div]:bg-yellow-500' :
                      '[&>div]:bg-green-500'
                    }`}
                  />

                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">{budget.budget_consumed_pct.toFixed(1)}% used</span>
                    <span className="font-medium text-muted-foreground">
                      ${budget.remaining_budget_usd.toFixed(2)} remaining
                    </span>
                  </div>

                  {/* Burn Rate & Depletion */}
                  <div className="pt-3 border-t space-y-2">
                    {budget.burn_rate_daily_usd && (
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-muted-foreground">Daily burn rate</span>
                        <span className="font-medium">${budget.burn_rate_daily_usd.toFixed(2)}/day</span>
                      </div>
                    )}
                    {budget.days_until_depletion && budget.days_until_depletion > 0 && (
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-muted-foreground">Days until depletion</span>
                        <span className={`font-medium ${budget.days_until_depletion < 7 ? 'text-red-600' : budget.days_until_depletion < 14 ? 'text-yellow-600' : ''}`}>
                          {budget.days_until_depletion} days
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Critical Alert */}
                  {budget.alert_status === 'red' && (
                    <div className="flex items-center gap-2 p-2 rounded bg-red-100 border border-red-300 mt-3">
                      <AlertTriangle className="h-4 w-4 text-red-700 flex-shrink-0" />
                      <span className="text-xs text-red-700 font-medium">
                        {budget.budget_consumed_pct >= 100
                          ? `Over budget by $${(budget.spent_to_date_usd - budget.allocated_budget_usd).toFixed(2)}`
                          : 'Critical: Take immediate action'}
                      </span>
                    </div>
                  )}
                  {budget.alert_status === 'yellow' && (
                    <div className="flex items-center gap-2 p-2 rounded bg-yellow-100 border border-yellow-300 mt-3">
                      <AlertTriangle className="h-4 w-4 text-yellow-700 flex-shrink-0" />
                      <span className="text-xs text-yellow-700 font-medium">
                        Approaching limit - Review spending
                      </span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
