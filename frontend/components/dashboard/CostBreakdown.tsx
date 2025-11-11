"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

interface CostItem {
  dimension: string;
  dimension_name: string;
  total_cost_usd: number;
  request_count: number;
  avg_cost_per_request: number;
  percentage_of_total: number;
}

interface CostBreakdownResponse {
  data: CostItem[];
  meta: {
    total_cost_usd: number;
    breakdown_by: string;
    total_items: number;
  };
}

const COLORS = [
  '#3b82f6', // blue
  '#10b981', // green
  '#f59e0b', // orange
  '#ef4444', // red
  '#8b5cf6', // purple
  '#ec4899', // pink
  '#14b8a6', // teal
  '#f97316', // orange-600
  '#06b6d4', // cyan
  '#84cc16', // lime
];

/**
 * CostBreakdown - Multi-dimensional cost analysis with pie and bar charts
 *
 * Features:
 * - Break down by department, model, version, environment
 * - Pie chart for percentage visualization
 * - Bar chart for absolute values
 * - Shows cost per request averages
 * - Color-coded for easy comparison
 */
export function CostBreakdown() {
  const { user } = useAuth();
  const { filters } = useFilters();
  const [breakdownBy, setBreakdownBy] = React.useState('department');
  const [viewMode, setViewMode] = React.useState<'pie' | 'bar'>('pie');

  const { data, isLoading } = useQuery<CostBreakdownResponse>({
    queryKey: ['cost-breakdown', filters.range, breakdownBy, filters.environment, filters.version],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);
      params.set('breakdown_by', breakdownBy);
      if (filters.environment) params.set('environment', filters.environment);
      if (filters.version) params.set('version', filters.version);

      const res = await fetch(`/api/v1/analytics/cost-breakdown?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      if (!res.ok) throw new Error('Failed to fetch cost breakdown');
      return res.json();
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Format chart data
  const chartData = data?.data.map((item, index) => ({
    name: item.dimension_name,
    value: item.total_cost_usd,
    percentage: item.percentage_of_total,
    requests: item.request_count,
    avgCost: item.avg_cost_per_request,
    fill: COLORS[index % COLORS.length],
  })) || [];

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Cost Breakdown</CardTitle>
          <CardDescription>Loading cost data...</CardDescription>
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
          <CardTitle>Cost Breakdown</CardTitle>
          <CardDescription>Multi-dimensional cost analysis</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">No cost data available for the selected filters</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Cost Breakdown</CardTitle>
            <CardDescription>
              Total: ${data.meta.total_cost_usd.toFixed(2)} • {filters.range}
            </CardDescription>
          </div>
          <Select value={breakdownBy} onValueChange={setBreakdownBy}>
            <SelectTrigger className="w-[160px]">
              <SelectValue placeholder="Break down by" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="department">By Department</SelectItem>
              <SelectItem value="model">By Model</SelectItem>
              <SelectItem value="version">By Version</SelectItem>
              <SelectItem value="environment">By Environment</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent>
        <Tabs value={viewMode} onValueChange={(v) => setViewMode(v as 'pie' | 'bar')}>
          <TabsList className="mb-4">
            <TabsTrigger value="pie">Pie Chart</TabsTrigger>
            <TabsTrigger value="bar">Bar Chart</TabsTrigger>
          </TabsList>

          <TabsContent value="pie" className="mt-0">
            <ResponsiveContainer width="100%" height={350}>
              <PieChart>
                <Pie
                  data={chartData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percentage }) => `${name}: ${percentage.toFixed(1)}%`}
                  outerRadius={120}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.fill} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(value: number) => `$${value.toFixed(2)}`}
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '6px',
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </TabsContent>

          <TabsContent value="bar" className="mt-0">
            <ResponsiveContainer width="100%" height={350}>
              <BarChart data={chartData} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis type="number" tick={{ fontSize: 12 }} stroke="#6b7280" />
                <YAxis
                  dataKey="name"
                  type="category"
                  width={120}
                  tick={{ fontSize: 12 }}
                  stroke="#6b7280"
                />
                <Tooltip
                  formatter={(value: number, name: string) => {
                    if (name === 'Cost') return [`$${value.toFixed(2)}`, 'Cost'];
                    return [value, name];
                  }}
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '6px',
                  }}
                />
                <Bar dataKey="value" name="Cost" radius={[0, 4, 4, 0]}>
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </TabsContent>
        </Tabs>

        {/* Cost details table */}
        <div className="mt-6 space-y-2">
          <h4 className="text-sm font-medium">Cost Details</h4>
          <div className="rounded-md border">
            <div className="grid grid-cols-4 gap-4 border-b bg-muted/50 p-3 text-xs font-medium">
              <div>{breakdownBy === 'department' ? 'Department' : breakdownBy === 'model' ? 'Model' : breakdownBy === 'version' ? 'Version' : 'Environment'}</div>
              <div className="text-right">Total Cost</div>
              <div className="text-right">Requests</div>
              <div className="text-right">Avg Cost/Req</div>
            </div>
            {data.data.map((item, index) => (
              <div
                key={item.dimension}
                className="grid grid-cols-4 gap-4 p-3 text-sm hover:bg-muted/50"
              >
                <div className="flex items-center gap-2">
                  <div
                    className="h-3 w-3 rounded-full"
                    style={{ backgroundColor: COLORS[index % COLORS.length] }}
                  />
                  <span className="font-medium">{item.dimension_name}</span>
                </div>
                <div className="text-right">${item.total_cost_usd.toFixed(2)}</div>
                <div className="text-right">{item.request_count.toLocaleString()}</div>
                <div className="text-right">${item.avg_cost_per_request.toFixed(4)}</div>
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
