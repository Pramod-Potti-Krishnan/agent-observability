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
  DollarSign,
  TrendingUp,
  TrendingDown,
  Activity,
  Zap,
  ChevronRight,
  ArrowUpDown
} from 'lucide-react';
import Link from 'next/link';

interface TopAgent {
  agent_id: string;
  total_cost: number;
  request_count: number;
  cost_per_request: number;
  total_tokens: number;
  cost_per_1k_tokens: number;
  avg_latency_ms: number;
  error_rate: number;
  optimization_potential: number;
  token_efficiency_score: number;
}

interface TopAgentsResponse {
  data: TopAgent[];
  meta: {
    range: string;
    total_agents: number;
    total_cost_all_agents: number;
  };
}

/**
 * TopCostlyAgentsTable - Ranked table of agents by cost with drill-down
 *
 * Features:
 * - Sortable by cost, requests, efficiency
 * - Time range selector
 * - Optimization potential indicators
 * - Click-through to agent detail pages
 * - Token efficiency scoring
 */
export function TopCostlyAgentsTable() {
  const { user, loading: authLoading } = useAuth();
  const [range, setRange] = useState('30d');
  const [sortBy, setSortBy] = useState('total_cost');
  const [limit, setLimit] = useState(20);

  const { data, isLoading } = useQuery<TopAgentsResponse>({
    queryKey: ['top-agents', range, sortBy, limit],
    queryFn: async () => {
      const params = new URLSearchParams({
        range,
        sort_by: sortBy,
        limit: limit.toString(),
      });

      const response = await apiClient.get(`/api/v1/cost/top-agents?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get efficiency badge
  const getEfficiencyBadge = (score: number): { variant: 'default' | 'secondary' | 'destructive', label: string } => {
    if (score >= 80) return { variant: 'secondary', label: 'Excellent' };
    if (score >= 60) return { variant: 'default', label: 'Good' };
    if (score >= 40) return { variant: 'default', label: 'Fair' };
    return { variant: 'destructive', label: 'Poor' };
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Top Costly Agents</CardTitle>
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
          <CardTitle>Top Costly Agents</CardTitle>
          <CardDescription>No agent data found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Activity className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Agent Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              No agents found for the selected time range
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
            <CardTitle>Top Costly Agents</CardTitle>
            <CardDescription>
              Showing top {data.data.length} of {data?.meta?.total_agents ?? 0} agents •
              ${data?.meta?.total_cost_all_agents?.toFixed(2) ?? '0.00'} total cost • {range}
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

            {/* Sort By Selector */}
            <Select value={sortBy} onValueChange={setSortBy}>
              <SelectTrigger className="w-[180px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="total_cost">Total Cost</SelectItem>
                <SelectItem value="cost_per_request">Cost per Request</SelectItem>
                <SelectItem value="request_count">Request Count</SelectItem>
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
        {/* Guard against incomplete meta data */}
        {(!data.meta?.total_cost_all_agents || data.meta.total_cost_all_agents === 0) ? (
          <div className="text-center py-12 text-muted-foreground">
            <p className="text-sm font-medium">No Cost Data Available</p>
            <p className="text-xs mt-1">No agents have generated costs in the selected time range</p>
          </div>
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow>
              <TableHead className="w-[50px]">Rank</TableHead>
              <TableHead>Agent ID</TableHead>
              <TableHead className="text-right">
                <div className="flex items-center justify-end gap-1">
                  Total Cost
                  <DollarSign className="h-3 w-3" />
                </div>
              </TableHead>
              <TableHead className="text-right">Requests</TableHead>
              <TableHead className="text-right">Cost/Request</TableHead>
              <TableHead className="text-right">Tokens</TableHead>
              <TableHead className="text-center">Efficiency</TableHead>
              <TableHead className="text-right">Optimization</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.data.map((agent, index) => {
              const efficiencyBadge = getEfficiencyBadge(agent.token_efficiency_score || 0);
              const costShare = ((agent.total_cost || 0) / (data.meta.total_cost_all_agents || 1)) * 100;

              return (
                <TableRow key={agent.agent_id} className="hover:bg-muted/50">
                  {/* Rank */}
                  <TableCell className="font-mono text-muted-foreground">
                    #{index + 1}
                  </TableCell>

                  {/* Agent ID */}
                  <TableCell>
                    <Link href={`/dashboard/performance/agents/${agent.agent_id}?tab=cost`} className="hover:underline">
                      <div className="flex flex-col">
                        <span className="font-mono text-sm font-medium text-primary">{agent.agent_id}</span>
                        <span className="text-xs text-muted-foreground">
                          {costShare.toFixed(1)}% of total
                        </span>
                      </div>
                    </Link>
                  </TableCell>

                  {/* Total Cost */}
                  <TableCell className="text-right">
                    <div className="flex flex-col items-end">
                      <span className="font-bold text-lg">
                        ${agent.total_cost.toFixed(2)}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        ${(agent.total_cost / 30).toFixed(2)}/day
                      </span>
                    </div>
                  </TableCell>

                  {/* Request Count */}
                  <TableCell className="text-right">
                    <div className="flex flex-col items-end">
                      <span className="font-medium">
                        {agent.request_count.toLocaleString()}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {(agent.request_count / 30).toFixed(0)}/day
                      </span>
                    </div>
                  </TableCell>

                  {/* Cost per Request */}
                  <TableCell className="text-right">
                    <span className="font-mono text-sm">
                      ${agent.cost_per_request.toFixed(4)}
                    </span>
                  </TableCell>

                  {/* Tokens */}
                  <TableCell className="text-right">
                    <div className="flex flex-col items-end">
                      <span className="font-medium text-sm">
                        {(agent.total_tokens / 1000).toFixed(0)}K
                      </span>
                      <span className="text-xs text-muted-foreground">
                        ${agent.cost_per_1k_tokens.toFixed(3)}/1K
                      </span>
                    </div>
                  </TableCell>

                  {/* Efficiency Score */}
                  <TableCell className="text-center">
                    <Badge variant={efficiencyBadge.variant} className="text-xs">
                      <Zap className="h-3 w-3 mr-1" />
                      {agent.token_efficiency_score.toFixed(0)}
                    </Badge>
                  </TableCell>

                  {/* Optimization Potential */}
                  <TableCell className="text-right">
                    <div className="flex flex-col items-end">
                      <span className="text-sm font-semibold text-green-600">
                        -${agent.optimization_potential.toFixed(2)}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {((agent.optimization_potential / agent.total_cost) * 100).toFixed(0)}% savings
                      </span>
                    </div>
                  </TableCell>

                  {/* Actions */}
                  <TableCell className="text-right">
                    <Link href={`/dashboard/performance/agents/${agent.agent_id}?tab=cost`}>
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
              <div className="grid grid-cols-4 gap-4">
                <div className="text-center">
                  <p className="text-xs text-muted-foreground mb-1">Total Cost</p>
                  <p className="text-xl font-bold">${data?.meta?.total_cost_all_agents?.toFixed(2) ?? '0.00'}</p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-muted-foreground mb-1">Total Requests</p>
                  <p className="text-xl font-bold">
                    {data?.data?.reduce((sum, a) => sum + a.request_count, 0).toLocaleString() ?? '0'}
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-muted-foreground mb-1">Avg Cost/Request</p>
                  <p className="text-xl font-bold">
                    ${((data?.meta?.total_cost_all_agents ?? 0) / (data?.data?.reduce((sum, a) => sum + a.request_count, 0) ?? 1)).toFixed(4)}
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-muted-foreground mb-1">Optimization Potential</p>
                  <p className="text-xl font-bold text-green-600">
                    ${data?.data?.reduce((sum, a) => sum + a.optimization_potential, 0).toFixed(2) ?? '0.00'}
                  </p>
                </div>
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
