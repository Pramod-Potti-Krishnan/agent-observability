"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Shield, AlertTriangle, TrendingUp, TrendingDown, Minus } from 'lucide-react';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';

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

interface AgentSafetyOverviewProps {
  agentId: string;
}

/**
 * AgentSafetyOverview - Safety metrics for a single agent
 *
 * Shows violation counts, risk score, trends, and breakdown by type/severity
 */
export function AgentSafetyOverview({ agentId }: AgentSafetyOverviewProps) {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data: allAgents, isLoading, error } = useQuery({
    queryKey: ['top-risky-agents', filters.range, 100], // Get more agents to find this one
    queryFn: async () => {
      const params = new URLSearchParams({
        time_range: filters.range,
        limit: '100', // Get enough to include this agent
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

  // Find this agent's data
  const agentData: AgentSafetyMetrics | undefined = allAgents?.agents.find(
    (a: AgentSafetyMetrics) => a.agent_id === agentId
  );

  // Get trend icon
  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'improving':
        return <TrendingDown className="h-5 w-5 text-green-600" />;
      case 'degrading':
        return <TrendingUp className="h-5 w-5 text-red-600" />;
      case 'stable':
      default:
        return <Minus className="h-5 w-5 text-gray-400" />;
    }
  };

  // Get risk badge variant
  const getRiskBadgeVariant = (riskScore: number): "default" | "secondary" | "destructive" | "outline" => {
    if (riskScore >= 70) return "destructive";
    if (riskScore >= 40) return "secondary";
    return "outline";
  };

  if (error) {
    return (
      <Alert variant="destructive">
        <AlertDescription>
          Failed to load safety metrics. Please try again later.
        </AlertDescription>
      </Alert>
    );
  }

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {[...Array(4)].map((_, i) => (
          <Card key={i}>
            <CardHeader className="pb-3">
              <Skeleton className="h-4 w-24" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-10 w-16" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  if (!agentData) {
    return (
      <Card>
        <CardContent className="py-12">
          <div className="flex flex-col items-center justify-center text-center">
            <Shield className="h-12 w-12 text-green-600 mb-2" />
            <p className="text-sm font-medium">No Safety Violations</p>
            <p className="text-xs text-muted-foreground mt-1">
              This agent has no recorded safety violations in the selected time range.
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Main KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Risk Score */}
        <Card className="hover:shadow-md transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Risk Score
            </CardTitle>
            <AlertTriangle className="h-5 w-5 text-orange-600" />
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              <Badge variant={getRiskBadgeVariant(agentData.risk_score)} className="text-lg px-3 py-1">
                {agentData.risk_score.toFixed(1)}
              </Badge>
              <span className="text-xs text-muted-foreground">/100</span>
            </div>
          </CardContent>
        </Card>

        {/* Total Violations */}
        <Card className="hover:shadow-md transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Violations
            </CardTitle>
            <Shield className="h-5 w-5 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{agentData.total_violations}</div>
            <p className="text-xs text-muted-foreground mt-1">
              {filters.range}
            </p>
          </CardContent>
        </Card>

        {/* Critical Violations */}
        <Card className="hover:shadow-md transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Critical
            </CardTitle>
            <AlertTriangle className="h-5 w-5 text-red-600" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-red-600">
              {agentData.critical_count}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              High: {agentData.high_count}
            </p>
          </CardContent>
        </Card>

        {/* Trend */}
        <Card className="hover:shadow-md transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Recent Trend
            </CardTitle>
            {getTrendIcon(agentData.recent_trend)}
          </CardHeader>
          <CardContent>
            <div className="text-lg font-medium capitalize">
              {agentData.recent_trend}
            </div>
            {agentData.last_violation && (
              <p className="text-xs text-muted-foreground mt-1">
                Last: {new Date(agentData.last_violation).toLocaleDateString()}
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Violation Type Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle>Violation Type Breakdown</CardTitle>
          <CardDescription>Distribution of violations by type</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* PII */}
            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div>
                <p className="text-sm font-medium">PII Detection</p>
                <p className="text-2xl font-bold mt-1">{agentData.pii_count}</p>
              </div>
              <Badge variant="outline" className="text-blue-600 border-blue-600">
                {agentData.total_violations > 0
                  ? ((agentData.pii_count / agentData.total_violations) * 100).toFixed(1)
                  : 0}%
              </Badge>
            </div>

            {/* Toxicity */}
            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div>
                <p className="text-sm font-medium">Toxicity</p>
                <p className="text-2xl font-bold mt-1">{agentData.toxicity_count}</p>
              </div>
              <Badge variant="outline" className="text-orange-600 border-orange-600">
                {agentData.total_violations > 0
                  ? ((agentData.toxicity_count / agentData.total_violations) * 100).toFixed(1)
                  : 0}%
              </Badge>
            </div>

            {/* Injection */}
            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div>
                <p className="text-sm font-medium">Prompt Injection</p>
                <p className="text-2xl font-bold mt-1">{agentData.injection_count}</p>
              </div>
              <Badge variant="outline" className="text-red-600 border-red-600">
                {agentData.total_violations > 0
                  ? ((agentData.injection_count / agentData.total_violations) * 100).toFixed(1)
                  : 0}%
              </Badge>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
