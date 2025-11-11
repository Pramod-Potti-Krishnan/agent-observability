"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Shield, TrendingUp, TrendingDown, Minus, ExternalLink } from 'lucide-react';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import Link from 'next/link';

interface AgentSafetyMetrics {
  agent_id: string;
  total_violations: number;
  critical_count: number;
  high_count: number;
  medium_count: number;
  pii_count: number;
  toxicity_count: number;
  injection_count: number;
  risk_score: number;
  recent_trend: 'improving' | 'stable' | 'degrading';
  last_violation?: string;
}

interface TopRiskyAgentsResponse {
  agents: AgentSafetyMetrics[];
  total_agents: number;
}

interface TopRiskyAgentsTableProps {
  limit?: number;
}

/**
 * TopRiskyAgentsTable - Agent-level safety metrics table
 *
 * Shows top agents ranked by risk score with violation breakdown,
 * trend indicators, and links to agent detail pages.
 */
export function TopRiskyAgentsTable({ limit = 20 }: TopRiskyAgentsTableProps) {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading, error } = useQuery<TopRiskyAgentsResponse>({
    queryKey: ['top-risky-agents', filters.range, limit],
    queryFn: async () => {
      const params = new URLSearchParams({
        time_range: filters.range,
        limit: limit.toString(),
      });
      const response = await apiClient.get(
        `/api/v1/guardrails/agents?${params.toString()}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get trend icon
  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'improving':
        return <TrendingDown className="h-4 w-4 text-green-600" />;
      case 'degrading':
        return <TrendingUp className="h-4 w-4 text-red-600" />;
      case 'stable':
      default:
        return <Minus className="h-4 w-4 text-gray-400" />;
    }
  };

  // Get risk badge color
  const getRiskBadgeVariant = (riskScore: number): "default" | "secondary" | "destructive" | "outline" => {
    if (riskScore >= 70) return "destructive";
    if (riskScore >= 40) return "secondary";
    return "outline";
  };

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Top Risky Agents</CardTitle>
          <CardDescription>Agent-level safety violations</CardDescription>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load risky agents. Please try again later.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Top Risky Agents</CardTitle>
          <CardDescription>Loading agent safety data...</CardDescription>
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
          <CardTitle>Top Risky Agents</CardTitle>
          <CardDescription>Agent-level safety violations</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <Shield className="h-12 w-12 text-green-600 mb-2" />
            <p className="text-sm font-medium">No Safety Violations</p>
            <p className="text-xs text-muted-foreground mt-1">
              All agents are operating within safety guidelines for the selected time range.
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
            <CardTitle>Top Risky Agents</CardTitle>
            <CardDescription>
              {data.total_agents} agents with violations • Ranked by risk score • {filters.range}
            </CardDescription>
          </div>
          <Badge variant="outline" className="text-xs">
            {data.agents.length} shown
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[200px]">Agent ID</TableHead>
                <TableHead className="text-center">Risk Score</TableHead>
                <TableHead className="text-center">Total</TableHead>
                <TableHead className="text-center">Critical</TableHead>
                <TableHead className="text-center">High</TableHead>
                <TableHead className="text-center">PII</TableHead>
                <TableHead className="text-center">Toxicity</TableHead>
                <TableHead className="text-center">Injection</TableHead>
                <TableHead className="text-center">Trend</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.agents.map((agent, index) => (
                <TableRow key={agent.agent_id} className="hover:bg-muted/50">
                  <TableCell className="font-mono text-xs font-medium">
                    <div className="flex items-center gap-2">
                      <span className="text-muted-foreground">#{index + 1}</span>
                      <span className="truncate max-w-[150px]">{agent.agent_id}</span>
                    </div>
                  </TableCell>
                  <TableCell className="text-center">
                    <Badge variant={getRiskBadgeVariant(agent.risk_score)}>
                      {agent.risk_score.toFixed(1)}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-center font-medium">
                    {agent.total_violations}
                  </TableCell>
                  <TableCell className="text-center">
                    {agent.critical_count > 0 ? (
                      <span className="font-medium text-red-600">{agent.critical_count}</span>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {agent.high_count > 0 ? (
                      <span className="font-medium text-orange-600">{agent.high_count}</span>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {agent.pii_count > 0 ? (
                      <span className="font-medium">{agent.pii_count}</span>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {agent.toxicity_count > 0 ? (
                      <span className="font-medium">{agent.toxicity_count}</span>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    {agent.injection_count > 0 ? (
                      <span className="font-medium">{agent.injection_count}</span>
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                  <TableCell className="text-center">
                    <div className="flex items-center justify-center gap-1">
                      {getTrendIcon(agent.recent_trend)}
                      <span className="text-xs capitalize">{agent.recent_trend}</span>
                    </div>
                  </TableCell>
                  <TableCell className="text-right">
                    <Link href={`/dashboard/performance/agents/${agent.agent_id}?tab=safety`}>
                      <Button variant="ghost" size="sm" className="h-7 text-xs">
                        View <ExternalLink className="ml-1 h-3 w-3" />
                      </Button>
                    </Link>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}
