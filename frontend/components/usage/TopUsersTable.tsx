"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { TrendingUp, TrendingDown, Minus, AlertTriangle } from 'lucide-react';

interface TopUsersItem {
  user_id: string;
  total_calls: number;
  agents_used: number;
  last_active: string;
  trend: 'up' | 'down' | 'stable';
  change_percentage: number;
  department?: string;
  total_cost_usd: number;
  risk_score?: number;
}

interface TopUsersResponse {
  data: TopUsersItem[];
  total_users: number;
}

/**
 * TopUsersTable - Enhanced table showing most active users
 *
 * Shows users sorted by API call volume with:
 * - User ID, calls, agents used, last active
 * - Department, cost, and risk score
 * - Trend indicators
 *
 * PRD Tab 2: Enhanced Top Users Table (P0)
 */
export function TopUsersTable() {
  const { user, loading: authLoading } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<TopUsersResponse>({
    queryKey: ['top-users', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/top-users?range=${filters.range}&limit=20`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  const TrendIcon = ({ change }: { change: number }) => {
    if (change > 0) return <TrendingUp className="h-4 w-4 text-green-500" />;
    if (change < 0) return <TrendingDown className="h-4 w-4 text-red-500" />;
    return <Minus className="h-4 w-4 text-gray-500" />;
  };

  const getRiskBadge = (score?: number) => {
    if (!score) return null;

    if (score >= 70) {
      return <Badge variant="destructive" className="text-xs">High Risk</Badge>;
    } else if (score >= 40) {
      return <Badge className="bg-yellow-500 text-white text-xs">Medium</Badge>;
    } else {
      return <Badge className="bg-green-500 text-white text-xs">Low</Badge>;
    }
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Top Users</CardTitle>
          <CardDescription>Loading user data...</CardDescription>
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
          <CardTitle>Top Users</CardTitle>
          <CardDescription>Most active users by API call volume</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <AlertTriangle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No User Data Available</p>
            <p className="text-xs text-muted-foreground mt-1">
              No user activity detected in the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Top Users</CardTitle>
        <CardDescription>
          Top {data.data.length} users by activity • {filters.range}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[200px]">User ID</TableHead>
                <TableHead className="text-right">Calls</TableHead>
                <TableHead className="text-right">Agents</TableHead>
                <TableHead>Department</TableHead>
                <TableHead className="text-right">Cost</TableHead>
                <TableHead className="text-center">Risk</TableHead>
                <TableHead className="text-right">Trend</TableHead>
                <TableHead className="text-right">Last Active</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.data.map((userItem, idx) => (
                <TableRow key={idx} className="hover:bg-muted/50">
                  <TableCell className="font-mono text-sm">
                    {userItem.user_id.length > 16
                      ? `${userItem.user_id.substring(0, 8)}...${userItem.user_id.substring(userItem.user_id.length - 4)}`
                      : userItem.user_id}
                  </TableCell>
                  <TableCell className="text-right font-medium">
                    {userItem.total_calls.toLocaleString()}
                  </TableCell>
                  <TableCell className="text-right text-muted-foreground">
                    {userItem.agents_used}
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className="text-xs">
                      {userItem.department || 'Unknown'}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right font-medium">
                    ${userItem.total_cost_usd.toFixed(2)}
                  </TableCell>
                  <TableCell className="text-center">
                    {getRiskBadge(userItem.risk_score)}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-1">
                      <TrendIcon change={userItem.change_percentage} />
                      <span className="text-sm text-muted-foreground">
                        {Math.abs(userItem.change_percentage).toFixed(0)}%
                      </span>
                    </div>
                  </TableCell>
                  <TableCell className="text-right text-xs text-muted-foreground">
                    {new Date(userItem.last_active).toLocaleString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {/* Risk Legend */}
        <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg text-xs">
          <p className="font-medium text-blue-900 mb-1">💡 Risk Score</p>
          <p className="text-blue-800">
            Calculated from error rate (40%) + cost per call (60%). High-risk users may need attention.
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
