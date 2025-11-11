"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { CheckCircle2, AlertTriangle, XCircle, Target, MoreVertical, Bell, Activity } from 'lucide-react';
import apiClient from '@/lib/api-client';
import { SetSLOModal } from './actions/SetSLOModal';
import { ProfileAgentModal } from './actions/ProfileAgentModal';
import { CreateAlertModal } from './actions/CreateAlertModal';
import { FlagRegressionModal } from './actions/FlagRegressionModal';

interface SLOTarget {
  p50_ms: number;
  p90_ms: number;
  p95_ms: number;
  p99_ms: number;
  error_rate_pct: number;
}

interface ActualMetrics {
  p50_ms: number;
  p90_ms: number;
  p95_ms: number;
  p99_ms: number;
  error_rate_pct: number;
}

interface Compliance {
  p50: boolean;
  p90: boolean;
  p95: boolean;
  p99: boolean;
  error_rate: boolean;
  overall_pct: number;
}

interface SLOData {
  agent_id: string;
  slo_targets: SLOTarget;
  actual_metrics: ActualMetrics;
  compliance: Compliance;
  status: string;
  request_count: number;
}

interface SLOComplianceResponse {
  data: SLOData[];
  meta: {
    range: string;
    total_agents: number;
    compliant_agents: number;
  };
}

/**
 * SLOComplianceTracker - Grid showing agent SLO compliance status
 *
 * Features:
 * - Shows compliance for P50/P90/P95/P99 latency and error rate
 * - Color-coded status (green: excellent, yellow: warning, red: critical)
 * - Overall compliance percentage per agent
 * - Identifies which agents are violating SLOs
 */
export function SLOComplianceTracker() {
  const { user } = useAuth();
  const { filters } = useFilters();
  const router = useRouter();

  // Modal state management
  const [selectedAgent, setSelectedAgent] = useState<string | null>(null);
  const [sloModalOpen, setSloModalOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);
  const [alertModalOpen, setAlertModalOpen] = useState(false);
  const [regressionModalOpen, setRegressionModalOpen] = useState(false);

  const { data, isLoading } = useQuery<SLOComplianceResponse>({
    queryKey: ['slo-compliance', filters.range],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);

      const res = await apiClient.get(`/api/v1/performance/slo-compliance?${params.toString()}`, {
        headers: {
          'X-Workspace-ID': user?.workspace_id || '',
        },
      });
      return res.data;
    },
    enabled: !!user?.workspace_id,
    staleTime: 3 * 60 * 1000, // 3 minutes
  });

  // Action handlers
  const handleSetSLO = (agentId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedAgent(agentId);
    setSloModalOpen(true);
  };

  const handleProfile = (agentId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedAgent(agentId);
    setProfileModalOpen(true);
  };

  const handleCreateAlert = (agentId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedAgent(agentId);
    setAlertModalOpen(true);
  };

  const handleFlagRegression = (agentId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedAgent(agentId);
    setRegressionModalOpen(true);
  };

  const handleRowClick = (agentId: string) => {
    router.push(`/dashboard/performance/agents/${agentId}`);
  };

  const getSelectedAgentData = () => {
    if (!selectedAgent || !data) return undefined;
    const agent = data.data.find(a => a.agent_id === selectedAgent);
    return agent ? {
      p50_ms: agent.slo_targets.p50_ms,
      p90_ms: agent.slo_targets.p90_ms,
      p95_ms: agent.slo_targets.p95_ms,
      p99_ms: agent.slo_targets.p99_ms,
      error_rate_pct: agent.slo_targets.error_rate_pct,
    } : undefined;
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'excellent':
        return <Badge className="bg-green-600">Excellent</Badge>;
      case 'good':
        return <Badge className="bg-blue-600">Good</Badge>;
      case 'warning':
        return <Badge variant="default">Warning</Badge>;
      case 'critical':
        return <Badge variant="destructive">Critical</Badge>;
      default:
        return <Badge variant="secondary">Unknown</Badge>;
    }
  };

  const ComplianceIcon = ({ compliant }: { compliant: boolean }) => {
    return compliant ? (
      <CheckCircle2 className="h-4 w-4 text-green-600" />
    ) : (
      <XCircle className="h-4 w-4 text-red-600" />
    );
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>SLO Compliance Tracker</CardTitle>
          <CardDescription>Loading SLO compliance data...</CardDescription>
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
          <CardTitle>SLO Compliance Tracker</CardTitle>
          <CardDescription>SLO compliance status for all agents</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Target className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No SLO Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              No SLO configurations found for the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const complianceRate = ((data.meta.compliant_agents / data.meta.total_agents) * 100).toFixed(1);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>SLO Compliance Tracker</CardTitle>
            <CardDescription>
              {data.meta.total_agents} agents • {data.meta.compliant_agents} compliant ({complianceRate}%)
            </CardDescription>
          </div>
          <Badge variant="secondary">{filters.range}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[200px]">Agent ID</TableHead>
                <TableHead className="text-center">P50</TableHead>
                <TableHead className="text-center">P90</TableHead>
                <TableHead className="text-center">P95</TableHead>
                <TableHead className="text-center">P99</TableHead>
                <TableHead className="text-center">Error Rate</TableHead>
                <TableHead className="text-center">Overall</TableHead>
                <TableHead className="text-center">Status</TableHead>
                <TableHead className="w-[50px]"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.data.map((agent) => (
                <TableRow
                  key={agent.agent_id}
                  className="cursor-pointer hover:bg-muted/50 transition-colors"
                  onClick={() => handleRowClick(agent.agent_id)}
                >
                  <TableCell className="font-mono text-sm">{agent.agent_id}</TableCell>

                  <TableCell className="text-center">
                    <div className="flex flex-col items-center gap-1">
                      <ComplianceIcon compliant={agent.compliance.p50} />
                      <div className="text-xs text-muted-foreground">
                        {agent.actual_metrics.p50_ms}ms / {agent.slo_targets.p50_ms}ms
                      </div>
                    </div>
                  </TableCell>

                  <TableCell className="text-center">
                    <div className="flex flex-col items-center gap-1">
                      <ComplianceIcon compliant={agent.compliance.p90} />
                      <div className="text-xs text-muted-foreground">
                        {agent.actual_metrics.p90_ms}ms / {agent.slo_targets.p90_ms}ms
                      </div>
                    </div>
                  </TableCell>

                  <TableCell className="text-center">
                    <div className="flex flex-col items-center gap-1">
                      <ComplianceIcon compliant={agent.compliance.p95} />
                      <div className="text-xs text-muted-foreground">
                        {agent.actual_metrics.p95_ms}ms / {agent.slo_targets.p95_ms}ms
                      </div>
                    </div>
                  </TableCell>

                  <TableCell className="text-center">
                    <div className="flex flex-col items-center gap-1">
                      <ComplianceIcon compliant={agent.compliance.p99} />
                      <div className="text-xs text-muted-foreground">
                        {agent.actual_metrics.p99_ms}ms / {agent.slo_targets.p99_ms}ms
                      </div>
                    </div>
                  </TableCell>

                  <TableCell className="text-center">
                    <div className="flex flex-col items-center gap-1">
                      <ComplianceIcon compliant={agent.compliance.error_rate} />
                      <div className="text-xs text-muted-foreground">
                        {agent.actual_metrics.error_rate_pct}% / {agent.slo_targets.error_rate_pct}%
                      </div>
                    </div>
                  </TableCell>

                  <TableCell className="text-center">
                    <div className="text-lg font-bold">
                      {agent.compliance.overall_pct}%
                    </div>
                    <div className="text-xs text-muted-foreground">
                      {agent.request_count.toLocaleString()} requests
                    </div>
                  </TableCell>

                  <TableCell className="text-center">
                    {getStatusBadge(agent.status)}
                  </TableCell>

                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-8 w-8 p-0"
                          onClick={(e) => e.stopPropagation()}
                        >
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end" className="w-48">
                        <DropdownMenuLabel>P0 Actions</DropdownMenuLabel>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem onClick={(e) => handleSetSLO(agent.agent_id, e as any)}>
                          <Target className="h-4 w-4 mr-2" />
                          Set SLO
                        </DropdownMenuItem>
                        <DropdownMenuItem onClick={(e) => handleProfile(agent.agent_id, e as any)}>
                          <Activity className="h-4 w-4 mr-2" />
                          Profile Agent
                        </DropdownMenuItem>
                        <DropdownMenuItem onClick={(e) => handleCreateAlert(agent.agent_id, e as any)}>
                          <Bell className="h-4 w-4 mr-2" />
                          Create Alert
                        </DropdownMenuItem>
                        <DropdownMenuItem onClick={(e) => handleFlagRegression(agent.agent_id, e as any)}>
                          <AlertTriangle className="h-4 w-4 mr-2" />
                          Flag Regression
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-3 gap-4 mt-6">
          <div className="p-4 rounded-lg bg-green-50 border border-green-200">
            <div className="flex items-center gap-2 mb-1">
              <CheckCircle2 className="h-4 w-4 text-green-600" />
              <span className="text-sm font-medium">Compliant</span>
            </div>
            <div className="text-2xl font-bold text-green-700">
              {data.meta.compliant_agents}
            </div>
          </div>

          <div className="p-4 rounded-lg bg-red-50 border border-red-200">
            <div className="flex items-center gap-2 mb-1">
              <XCircle className="h-4 w-4 text-red-600" />
              <span className="text-sm font-medium">Non-Compliant</span>
            </div>
            <div className="text-2xl font-bold text-red-700">
              {data.meta.total_agents - data.meta.compliant_agents}
            </div>
          </div>

          <div className="p-4 rounded-lg bg-blue-50 border border-blue-200">
            <div className="flex items-center gap-2 mb-1">
              <Target className="h-4 w-4 text-blue-600" />
              <span className="text-sm font-medium">Compliance Rate</span>
            </div>
            <div className="text-2xl font-bold text-blue-700">
              {complianceRate}%
            </div>
          </div>
        </div>
      </CardContent>

      {/* Action Modals */}
      {selectedAgent && (
        <>
          <SetSLOModal
            isOpen={sloModalOpen}
            onClose={() => setSloModalOpen(false)}
            agentId={selectedAgent}
            currentSLO={getSelectedAgentData()}
          />
          <ProfileAgentModal
            isOpen={profileModalOpen}
            onClose={() => setProfileModalOpen(false)}
            agentId={selectedAgent}
          />
          <CreateAlertModal
            isOpen={alertModalOpen}
            onClose={() => setAlertModalOpen(false)}
            agentId={selectedAgent}
          />
          <FlagRegressionModal
            isOpen={regressionModalOpen}
            onClose={() => setRegressionModalOpen(false)}
            agentId={selectedAgent}
          />
        </>
      )}
    </Card>
  );
}
