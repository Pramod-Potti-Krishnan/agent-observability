'use client'

import React, { useState, useEffect, Suspense } from 'react';
import { useParams, useRouter, useSearchParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { KPICard } from '@/components/dashboard/KPICard';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
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
import { ArrowLeft, Target, Activity, Bell, AlertTriangle, Clock, CheckCircle2, XCircle, BarChart3, Shield, DollarSign, TrendingUp } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { SetSLOModal } from '@/components/performance/actions/SetSLOModal';
import { ProfileAgentModal } from '@/components/performance/actions/ProfileAgentModal';
import { CreateAlertModal } from '@/components/performance/actions/CreateAlertModal';
import { FlagRegressionModal } from '@/components/performance/actions/FlagRegressionModal';
import { AgentQualityOverview } from '@/components/quality/agent/AgentQualityOverview';
import { AgentQualityTimeline } from '@/components/quality/agent/AgentQualityTimeline';
import { AgentSafetyOverview } from '@/components/quality/agent/AgentSafetyOverview';
import { AgentCriteriaBreakdown } from '@/components/quality/agent/AgentCriteriaBreakdown';
import { AgentEvaluationsList } from '@/components/quality/agent/AgentEvaluationsList';
import { AgentCostTrendChart } from '@/components/cost/agent/AgentCostTrendChart';
import { AgentModelBreakdown } from '@/components/cost/agent/AgentModelBreakdown';
import { AgentTokenEfficiency } from '@/components/cost/agent/AgentTokenEfficiency';
import { AgentCostComparison } from '@/components/cost/agent/AgentCostComparison';
import { AgentCostByDepartment } from '@/components/cost/agent/AgentCostByDepartment';

interface AgentMetrics {
  p50_ms: number;
  p90_ms: number;
  p95_ms: number;
  p99_ms: number;
  avg_latency_ms: number;
  error_rate_pct: number;
  success_rate_pct: number;
  request_count: number;
  requests_per_second: number;
}

interface SLOConfig {
  p50_ms: number;
  p90_ms: number;
  p95_ms: number;
  p99_ms: number;
  error_rate_pct: number;
}

interface RecentTrace {
  trace_id: string;
  timestamp: string;
  latency_ms: number;
  status: string;
  error_message?: string;
}

interface AgentDetailResponse {
  agent_id: string;
  metrics: AgentMetrics;
  slo_config: SLOConfig | null;
  recent_traces: RecentTrace[];
}

export default function AgentDetailPage() {
  const params = useParams();
  const router = useRouter();
  const searchParams = useSearchParams();
  const { user } = useAuth();
  const { filters } = useFilters();
  const agentId = params.agent_id as string;

  // Get tab from URL query parameter, default to 'performance'
  const urlTab = searchParams.get('tab') || 'performance';
  const [activeTab, setActiveTab] = useState(urlTab);

  // Update active tab when URL changes
  useEffect(() => {
    setActiveTab(urlTab);
  }, [urlTab]);

  // Modal state
  const [sloModalOpen, setSloModalOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);
  const [alertModalOpen, setAlertModalOpen] = useState(false);
  const [regressionModalOpen, setRegressionModalOpen] = useState(false);

  const { data, isLoading, error } = useQuery<AgentDetailResponse>({
    queryKey: ['agent-detail', agentId, filters.range],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);

      const response = await apiClient.get(
        `/api/v1/performance/agents/${agentId}?${params.toString()}`,
        {
          headers: {
            'X-Workspace-ID': user?.workspace_id || '',
          },
        }
      );
      return response.data;
    },
    enabled: !!user?.workspace_id && !!agentId,
    staleTime: 3 * 60 * 1000,
  });

  // Fetch quality data for the agent
  const { data: qualityData, isLoading: qualityLoading, refetch: refetchQualityData } = useQuery({
    queryKey: ['agent-quality', agentId, filters.range],
    queryFn: async () => {
      const params = new URLSearchParams();
      params.set('range', filters.range);
      params.set('granularity', 'daily');

      const response = await apiClient.get(
        `/api/v1/quality/agent/${agentId}?${params.toString()}`,
        {
          headers: {
            'X-Workspace-ID': user?.workspace_id || '',
          },
        }
      );
      return response.data;
    },
    enabled: !!user?.workspace_id && !!agentId,
    staleTime: 3 * 60 * 1000,
  });

  const getStatusBadge = (status: string) => {
    switch (status.toLowerCase()) {
      case 'success':
        return <Badge className="bg-green-600">Success</Badge>;
      case 'error':
        return <Badge variant="destructive">Error</Badge>;
      case 'timeout':
        return <Badge variant="default">Timeout</Badge>;
      default:
        return <Badge variant="secondary">{status}</Badge>;
    }
  };

  const getSLOCompliance = () => {
    if (!data?.metrics || !data?.slo_config) return null;

    const { metrics, slo_config } = data;
    const compliance = {
      p50: metrics.p50_ms <= slo_config.p50_ms,
      p90: metrics.p90_ms <= slo_config.p90_ms,
      p95: metrics.p95_ms <= slo_config.p95_ms,
      p99: metrics.p99_ms <= slo_config.p99_ms,
      error_rate: metrics.error_rate_pct <= slo_config.error_rate_pct,
    };

    const compliantCount = Object.values(compliance).filter(Boolean).length;
    const overallPct = (compliantCount / 5) * 100;

    return { compliance, overallPct };
  };

  const sloStatus = getSLOCompliance();

  if (isLoading) {
    return (
      <div className="p-8 space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
        <Skeleton className="h-96" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="p-8">
        <Button variant="ghost" onClick={() => router.back()} className="mb-4">
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Performance
        </Button>
        <Card>
          <CardContent className="flex items-center justify-center py-12">
            <div className="text-center">
              <XCircle className="h-12 w-12 text-destructive mx-auto mb-2" />
              <p className="text-lg font-semibold">Failed to Load Agent Details</p>
              <p className="text-sm text-muted-foreground mt-1">
                Unable to fetch data for agent {agentId}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-8 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="space-y-1">
          <Button variant="ghost" onClick={() => router.back()} className="mb-2 -ml-4">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
          <h1 className="text-3xl font-bold">Agent Details</h1>
          <p className="text-sm text-muted-foreground font-mono">{agentId}</p>
        </div>

        {/* Action Buttons */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button>P0 Actions</Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-48">
            <DropdownMenuLabel>Performance Actions</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => setSloModalOpen(true)}>
              <Target className="h-4 w-4 mr-2" />
              Set SLO
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setProfileModalOpen(true)}>
              <Activity className="h-4 w-4 mr-2" />
              Profile Agent
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setAlertModalOpen(true)}>
              <Bell className="h-4 w-4 mr-2" />
              Create Alert
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setRegressionModalOpen(true)}>
              <AlertTriangle className="h-4 w-4 mr-2" />
              Flag Regression
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {/* Tabs for different aspects */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList>
          <TabsTrigger value="performance">
            <BarChart3 className="h-4 w-4 mr-2" />
            Performance
          </TabsTrigger>
          <TabsTrigger value="quality">
            <Target className="h-4 w-4 mr-2" />
            Quality
          </TabsTrigger>
          <TabsTrigger value="safety">
            <Shield className="h-4 w-4 mr-2" />
            Safety
          </TabsTrigger>
          <TabsTrigger value="cost">
            <DollarSign className="h-4 w-4 mr-2" />
            Cost
          </TabsTrigger>
          <TabsTrigger value="impact" disabled>
            <TrendingUp className="h-4 w-4 mr-2" />
            Impact
          </TabsTrigger>
        </TabsList>

        <TabsContent value="performance" className="space-y-6">
      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          title="P50 Latency"
          value={`${Math.round(data.metrics.p50_ms)}ms`}
          change={0}
          changeLabel="median response"
          trend="inverse"
          loading={false}
        />
        <KPICard
          title="P95 Latency"
          value={`${Math.round(data.metrics.p95_ms)}ms`}
          change={0}
          changeLabel="95th percentile"
          trend="inverse"
          loading={false}
        />
        <KPICard
          title="P99 Latency"
          value={`${Math.round(data.metrics.p99_ms)}ms`}
          change={0}
          changeLabel="99th percentile"
          trend="inverse"
          loading={false}
        />
        <KPICard
          title="Error Rate"
          value={`${data.metrics.error_rate_pct.toFixed(2)}%`}
          change={0}
          changeLabel={`${data.metrics.request_count.toLocaleString()} requests`}
          trend="inverse"
          loading={false}
        />
      </div>

      {/* SLO Compliance Card */}
      {data.slo_config && sloStatus && (
        <Card>
          <CardHeader>
            <CardTitle>SLO Compliance</CardTitle>
            <CardDescription>
              Current performance against configured SLO targets
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-5 gap-4">
              {['p50', 'p90', 'p95', 'p99', 'error_rate'].map((metric) => {
                const isCompliant = sloStatus.compliance[metric as keyof typeof sloStatus.compliance];
                const metricLabel = metric.toUpperCase().replace('_', ' ');
                const actualValue =
                  metric === 'error_rate'
                    ? data.metrics.error_rate_pct.toFixed(2)
                    : Math.round(data.metrics[`${metric}_ms` as keyof AgentMetrics] as number);
                const targetValue =
                  metric === 'error_rate'
                    ? data.slo_config!.error_rate_pct.toFixed(2)
                    : data.slo_config![`${metric}_ms` as keyof SLOConfig];
                const unit = metric === 'error_rate' ? '%' : 'ms';

                return (
                  <div
                    key={metric}
                    className={`p-4 rounded-lg border ${isCompliant ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'}`}
                  >
                    <div className="flex items-center gap-2 mb-2">
                      {isCompliant ? (
                        <CheckCircle2 className="h-4 w-4 text-green-600" />
                      ) : (
                        <XCircle className="h-4 w-4 text-red-600" />
                      )}
                      <span className="text-xs font-semibold">{metricLabel}</span>
                    </div>
                    <div className="text-sm">
                      <div className="font-bold">{actualValue}{unit}</div>
                      <div className="text-xs text-muted-foreground">
                        Target: {targetValue}{unit}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="mt-4 p-3 rounded-lg bg-blue-50 border border-blue-200">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">Overall Compliance</span>
                <span className="text-2xl font-bold text-blue-700">
                  {sloStatus.overallPct.toFixed(0)}%
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* No SLO Configured */}
      {!data.slo_config && (
        <Card>
          <CardHeader>
            <CardTitle>SLO Configuration</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <Target className="h-12 w-12 text-muted-foreground mb-2" />
              <p className="text-sm font-medium mb-3">No SLO Configured</p>
              <Button onClick={() => setSloModalOpen(true)}>
                <Target className="h-4 w-4 mr-2" />
                Set SLO Targets
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recent Traces */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Traces</CardTitle>
          <CardDescription>
            Last {data.recent_traces.length} traces for this agent
          </CardDescription>
        </CardHeader>
        <CardContent>
          {data.recent_traces.length > 0 ? (
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[200px]">Trace ID</TableHead>
                    <TableHead>Timestamp</TableHead>
                    <TableHead className="text-right">Latency</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Error Message</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {data.recent_traces.map((trace) => (
                    <TableRow key={trace.trace_id}>
                      <TableCell className="font-mono text-xs">
                        {trace.trace_id.substring(0, 16)}...
                      </TableCell>
                      <TableCell className="text-sm">
                        {new Date(trace.timestamp).toLocaleString()}
                      </TableCell>
                      <TableCell className="text-right font-medium">
                        {Math.round(trace.latency_ms)}ms
                      </TableCell>
                      <TableCell>{getStatusBadge(trace.status)}</TableCell>
                      <TableCell className="text-sm text-muted-foreground max-w-[300px] truncate">
                        {trace.error_message || '—'}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <Clock className="h-12 w-12 text-muted-foreground mb-2" />
              <p className="text-sm font-medium">No Recent Traces</p>
              <p className="text-xs text-muted-foreground mt-1">
                No traces found for the selected time range
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Performance Summary */}
      <Card>
        <CardHeader>
          <CardTitle>Performance Summary</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Average Latency</p>
              <p className="text-2xl font-bold">{Math.round(data.metrics.avg_latency_ms)}ms</p>
            </div>
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Success Rate</p>
              <p className="text-2xl font-bold text-green-600">
                {data.metrics.success_rate_pct.toFixed(1)}%
              </p>
            </div>
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Requests/Second</p>
              <p className="text-2xl font-bold">
                {data.metrics.requests_per_second.toFixed(2)}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

        </TabsContent>

        {/* Placeholder tabs for future implementation */}
        <TabsContent value="quality" className="space-y-6">
          {/* Quality Overview KPIs */}
          <AgentQualityOverview
            agentId={agentId}
            avgScore={qualityData?.avg_score || 0}
            totalEvaluations={qualityData?.total_evaluations || 0}
            failingRate={qualityData?.failing_rate || 0}
            recentTrend={qualityData?.recent_trend || 'stable'}
            driftIndicator={qualityData?.drift_indicator || 0}
            loading={qualityLoading}
            onRefresh={() => refetchQualityData()}
          />

          {/* Two-column layout for charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <AgentQualityTimeline
              data={qualityData?.timeline || []}
              loading={qualityLoading}
            />
            <AgentCriteriaBreakdown
              criteria={qualityData?.criteria_breakdown || { accuracy: 0, relevance: 0, helpfulness: 0, coherence: 0 }}
              loading={qualityLoading}
            />
          </div>

          {/* Recent Evaluations Table */}
          <AgentEvaluationsList
            evaluations={qualityData?.recent_evaluations || []}
            loading={qualityLoading}
          />
        </TabsContent>

        <TabsContent value="safety" className="space-y-6">
          {/* Agent Safety Overview */}
          <AgentSafetyOverview agentId={agentId} />
        </TabsContent>

        <TabsContent value="cost" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <AgentCostTrendChart agentId={agentId} timeRange={filters.range} />
            <AgentModelBreakdown agentId={agentId} timeRange={filters.range} />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <AgentTokenEfficiency agentId={agentId} timeRange={filters.range} />
            <AgentCostComparison agentId={agentId} timeRange={filters.range} />
          </div>

          <AgentCostByDepartment agentId={agentId} timeRange={filters.range} />
        </TabsContent>

        <TabsContent value="impact">
          <Card>
            <CardHeader>
              <CardTitle>Business Impact</CardTitle>
              <CardDescription>Business metrics and ROI for this agent will be displayed here</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">Coming soon...</p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Action Modals */}
      <SetSLOModal
        isOpen={sloModalOpen}
        onClose={() => setSloModalOpen(false)}
        agentId={agentId}
        currentSLO={data.slo_config || undefined}
      />
      <ProfileAgentModal
        isOpen={profileModalOpen}
        onClose={() => setProfileModalOpen(false)}
        agentId={agentId}
      />
      <CreateAlertModal
        isOpen={alertModalOpen}
        onClose={() => setAlertModalOpen(false)}
        agentId={agentId}
      />
      <FlagRegressionModal
        isOpen={regressionModalOpen}
        onClose={() => setRegressionModalOpen(false)}
        agentId={agentId}
      />
    </div>
  );
}
