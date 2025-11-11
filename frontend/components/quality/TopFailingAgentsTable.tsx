"use client";

import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  AlertTriangle,
  TrendingUp,
  TrendingDown,
  Minus,
  ChevronRight,
  AlertCircle
} from 'lucide-react';
import Link from 'next/link';

interface FailingAgent {
  agent_id: string;
  avg_score: number;
  evaluation_count: number;
  failing_rate: number;
  recent_trend: 'improving' | 'stable' | 'degrading';
  cost_impact_usd: number;
  last_failure: string | null;
}

interface FailingAgentsResponse {
  data: FailingAgent[];
  total_failing_agents: number;
}

/**
 * TopFailingAgentsTable - Ranked table of agents with quality issues
 *
 * Features:
 * - Sortable by failing rate, avg score
 * - Time range selector
 * - Trend indicators (improving/degrading/stable)
 * - Click-through to agent detail pages
 * - Failure rate percentage with visual indicators
 */
export function TopFailingAgentsTable() {
  const { user, loading: authLoading } = useAuth();
  const [range, setRange] = useState('7d');
  const [limit, setLimit] = useState(20);

  const { data, isLoading } = useQuery<FailingAgentsResponse>({
    queryKey: ['top-failing-agents', range, limit],
    queryFn: async () => {
      const params = new URLSearchParams({
        range,
        limit: limit.toString(),
      });

      const response = await apiClient.get(`/api/v1/quality/agents?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get trend icon and color
  const getTrendDisplay = (trend: string) => {
    if (trend === 'improving') {
      return {
        icon: <TrendingUp className="h-4 w-4" />,
        color: 'text-green-600',
        label: 'Improving'
      };
    } else if (trend === 'degrading') {
      return {
        icon: <TrendingDown className="h-4 w-4" />,
        color: 'text-red-600',
        label: 'Degrading'
      };
    } else {
      return {
        icon: <Minus className="h-4 w-4" />,
        color: 'text-gray-600',
        label: 'Stable'
      };
    }
  };

  // Get severity badge based on failing rate
  const getSeverityBadge = (failingRate: number): { variant: 'default' | 'secondary' | 'destructive', label: string } => {
    if (failingRate >= 50) return { variant: 'destructive', label: 'Critical' };
    if (failingRate >= 30) return { variant: 'destructive', label: 'High' };
    if (failingRate >= 10) return { variant: 'default', label: 'Medium' };
    return { variant: 'secondary', label: 'Low' };
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Top Failing Agents</CardTitle>
          <CardDescription>Loading agent data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[500px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Top Failing Agents</CardTitle>
          <CardDescription>No failing agents found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <AlertCircle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Failing Agents</p>
            <p className="text-xs text-muted-foreground mt-1">
              All agents are performing well in the selected time range
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
            <CardTitle>Top Failing Agents</CardTitle>
            <CardDescription>
              Showing top {data.data.length} agents with quality issues • {data.total_failing_agents} total failing agents • {range}
            </CardDescription>
          </div>
          <div className="flex gap-2">
            {/* Time Range Selector */}
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

            {/* Limit Selector */}
            <Select value={limit.toString()} onValueChange={(val) => setLimit(parseInt(val))}>
              <SelectTrigger className="w-[100px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="10">Top 10</SelectItem>
                <SelectItem value="20">Top 20</SelectItem>
                <SelectItem value="50">Top 50</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-[50px]">Rank</TableHead>
              <TableHead>Agent ID</TableHead>
              <TableHead className="text-right">Avg Score</TableHead>
              <TableHead className="text-right">Failing Rate</TableHead>
              <TableHead className="text-center">Severity</TableHead>
              <TableHead className="text-right">Evaluations</TableHead>
              <TableHead className="text-center">Trend</TableHead>
              <TableHead className="text-right">Last Failure</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.data.map((agent, index) => {
              const trend = getTrendDisplay(agent.recent_trend);
              const severity = getSeverityBadge(agent.failing_rate);
              const lastFailure = agent.last_failure ? new Date(agent.last_failure) : null;

              return (
                <TableRow key={agent.agent_id} className="hover:bg-muted/50">
                  {/* Rank */}
                  <TableCell className="font-mono text-muted-foreground">
                    #{index + 1}
                  </TableCell>

                  {/* Agent ID */}
                  <TableCell>
                    <div className="flex flex-col">
                      <span className="font-mono text-sm font-medium">{agent.agent_id}</span>
                      <span className="text-xs text-muted-foreground">
                        {(agent.failing_rate || 0).toFixed(1)}% failure rate
                      </span>
                    </div>
                  </TableCell>

                  {/* Average Score */}
                  <TableCell className="text-right">
                    <div className="flex flex-col items-end">
                      <span className={`font-bold text-lg ${(agent.avg_score || 0) < 5 ? 'text-red-600' : 'text-amber-600'}`}>
                        {(agent.avg_score || 0).toFixed(2)}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        out of 10.0
                      </span>
                    </div>
                  </TableCell>

                  {/* Failing Rate */}
                  <TableCell className="text-right">
                    <div className="flex flex-col items-end">
                      <span className="font-medium text-lg text-red-600">
                        {(agent.failing_rate || 0).toFixed(1)}%
                      </span>
                      <span className="text-xs text-muted-foreground">
                        below threshold
                      </span>
                    </div>
                  </TableCell>

                  {/* Severity Badge */}
                  <TableCell className="text-center">
                    <Badge variant={severity.variant} className="text-xs">
                      <AlertTriangle className="h-3 w-3 mr-1" />
                      {severity.label}
                    </Badge>
                  </TableCell>

                  {/* Evaluation Count */}
                  <TableCell className="text-right">
                    <span className="font-medium">
                      {agent.evaluation_count}
                    </span>
                  </TableCell>

                  {/* Trend */}
                  <TableCell className="text-center">
                    <div className={`flex items-center justify-center gap-1 ${trend.color}`}>
                      {trend.icon}
                      <span className="text-xs font-medium">{trend.label}</span>
                    </div>
                  </TableCell>

                  {/* Last Failure */}
                  <TableCell className="text-right">
                    {lastFailure ? (
                      <div className="flex flex-col items-end">
                        <span className="text-sm">
                          {lastFailure.toLocaleDateString()}
                        </span>
                        <span className="text-xs text-muted-foreground">
                          {lastFailure.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </div>
                    ) : (
                      <span className="text-xs text-muted-foreground">—</span>
                    )}
                  </TableCell>

                  {/* Actions */}
                  <TableCell className="text-right">
                    <Link href={`/dashboard/performance/agents/${agent.agent_id}?tab=quality`}>
                      <Button variant="ghost" size="sm">
                        Details
                        <ChevronRight className="h-4 w-4 ml-1" />
                      </Button>
                    </Link>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>

        {/* Summary Footer */}
        <div className="mt-6 pt-4 border-t">
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Total Failing Agents</p>
              <p className="text-xl font-bold text-red-600">{data.total_failing_agents}</p>
            </div>
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Avg Failing Rate</p>
              <p className="text-xl font-bold">
                {(data.data.length > 0 ? data.data.reduce((sum, a) => sum + (a.failing_rate || 0), 0) / data.data.length : 0).toFixed(1)}%
              </p>
            </div>
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Total Evaluations</p>
              <p className="text-xl font-bold">
                {data.data.reduce((sum, a) => sum + (a.evaluation_count || 0), 0)}
              </p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
